import 'dart:async';

import 'package:flutter/foundation.dart';

import 'core/engine/vpn_core_adapter.dart';
import 'core/engine/xray_adapter.dart';
import 'core/import/profile_detector.dart';
import 'core/model/pv_profile.dart';
import 'core/storage/profile_repository.dart';

enum PVLinkState { disconnected, connecting, connected, disconnecting, error }

/// Resolves the adapter that must serve a profile, based on the profile's
/// `engineRequirements.engine`. Unknown engines resolve to null so callers
/// can refuse honestly instead of silently mis-routing traffic.
class EngineRegistry {
  final Map<String, VpnCoreAdapter> _adapters = <String, VpnCoreAdapter>{};

  void register(VpnCoreAdapter adapter) => _adapters[adapter.id] = adapter;

  VpnCoreAdapter? operator [](String id) => _adapters[id];

  VpnCoreAdapter? forProfile(PVProfile profile) {
    final required = profile.engineRequirements['engine'];
    final canonical = switch (required) {
      null || '' || 'generic' || 'xray' || 'xray-json' => 'xray-core',
      final other => other,
    };
    return _adapters[canonical];
  }

  List<VpnCoreAdapter> get all => List.unmodifiable(_adapters.values);
}

class PVController extends ChangeNotifier {
  PVController(this.repository, {VpnCoreAdapter? primaryAdapter})
      : registry = EngineRegistry() {
    final adapter = primaryAdapter ?? XrayAdapter(repository: repository);
    registry.register(adapter);
    _adapter = adapter;
    _adapterSubscription = adapter.events.listen(_onAdapterEvent);
  }

  final ProfileRepository repository;
  final EngineRegistry registry;
  late final VpnCoreAdapter _adapter;
  StreamSubscription<VpnCoreEvent>? _adapterSubscription;
  Timer? _statsTimer;

  final List<PVProfile> profiles = <PVProfile>[];
  String? selectedId;

  PVLinkState linkState = PVLinkState.disconnected;
  String? lastError;
  VpnCoreStatistics? stats;

  PVProfile? get selected {
    for (final profile in profiles) {
      if (profile.id == selectedId) return profile;
    }
    return null;
  }

  VpnCoreAdapter? get adapter => _adapter;

  bool get isBusy => linkState == PVLinkState.connecting || linkState == PVLinkState.disconnecting;

  /// Adapter that can honestly serve the selected profile, or null.
  VpnCoreAdapter? adapterFor(PVProfile? profile) => profile == null ? null : registry.forProfile(profile);

  Future<void> load() async {
    profiles.addAll(await repository.loadProfiles());
    selectedId = await repository.loadSelectedProfileId();
    if (selected == null && profiles.isNotEmpty) selectedId = profiles.first.id;
    notifyListeners();
  }

  Future<void> addRaw(String value, {String source = 'text'}) async {
    final profile = detector.detect(value, sourceType: source).toProfile();
    profiles.insert(0, profile);
    selectedId ??= profile.id;
    await persist();
  }

  Future<void> select(String id) async {
    selectedId = id;
    await repository.saveSelectedProfileId(id);
    notifyListeners();
  }

  /// Selects [id] and, when the tunnel is up, migrates to the new profile.
  Future<void> switchProfile(String id) async {
    final wasConnected = linkState == PVLinkState.connected;
    if (wasConnected) await disconnect();
    await select(id);
    if (wasConnected) await connect();
  }

  Future<void> remove(String id) async {
    if (selectedId == id && linkState != PVLinkState.disconnected) await disconnect();
    final target = profiles.where((p) => p.id == id).firstOrNull;
    profiles.removeWhere((profile) => profile.id == id);
    if (selectedId == id) selectedId = profiles.isEmpty ? null : profiles.first.id;
    if (target != null) {
      try {
        await repository.deleteProfileSecrets(target);
      } catch (_) {
        // Secret cleanup must never block profile removal.
      }
    }
    await persist();
  }

  Future<void> connect() async {
    final profile = selected;
    if (profile == null || isBusy) return;
    final chosen = adapterFor(profile);
    if (chosen == null) {
      lastError =
          'No enabled engine for "${profile.engineRequirements['engine'] ?? profile.protocol}". Import a VLESS/VMess/Trojan/Shadowsocks/SOCKS/HTTP profile or wait for the matching adapter.';
      linkState = PVLinkState.error;
      notifyListeners();
      return;
    }
    lastError = null;
    linkState = PVLinkState.connecting;
    notifyListeners();
    try {
      final caps = await chosen.probeCapabilities();
      if (caps.protocols.isEmpty) {
        throw StateError('The ${caps.engine} is not available on this platform yet.');
      }
      final issues = await chosen.validateProfile(profile);
      if (issues.isNotEmpty) {
        throw StateError(issues.join(' '));
      }
      await chosen.start(profile);
      _statsTimer?.cancel();
      _statsTimer = Timer.periodic(const Duration(seconds: 3), (_) => refreshStats());
    } catch (e) {
      lastError = e.toString();
      linkState = PVLinkState.error;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (isBusy) return;
    linkState = PVLinkState.disconnecting;
    notifyListeners();
    try {
      await _adapter.stop();
    } catch (e) {
      lastError = e.toString();
    } finally {
      _statsTimer?.cancel();
      stats = null;
      notifyListeners();
    }
  }

  Future<void> toggle() => linkState == PVLinkState.connected ? disconnect() : connect();

  Future<void> refreshStats() async {
    if (linkState != PVLinkState.connected) return;
    try {
      stats = await _adapter.getStatistics();
      notifyListeners();
    } catch (_) {
      // Transient probe failures are surfaced through the next tick.
    }
  }

  void clearError() {
    lastError = null;
    if (linkState == PVLinkState.error) linkState = PVLinkState.disconnected;
    notifyListeners();
  }

  void _onAdapterEvent(VpnCoreEvent event) {
    linkState = switch (event.state) {
      VpnConnectionState.connecting ||
      VpnConnectionState.preparing ||
      VpnConnectionState.requestingPermission ||
      VpnConnectionState.authenticating ||
      VpnConnectionState.establishingTunnel ||
      VpnConnectionState.reconnecting => PVLinkState.connecting,
      VpnConnectionState.connected => PVLinkState.connected,
      VpnConnectionState.disconnecting => PVLinkState.disconnecting,
      VpnConnectionState.disconnected => PVLinkState.disconnected,
      VpnConnectionState.error => PVLinkState.error,
    };
    if (event.message != null) lastError = event.message;
    notifyListeners();
  }

  Future<void> persist() async {
    await repository.saveProfiles(profiles);
    await repository.saveSelectedProfileId(selectedId);
    notifyListeners();
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _adapterSubscription?.cancel();
    super.dispose();
  }

  static final ProfileDetector detector = ProfileDetector();
}
