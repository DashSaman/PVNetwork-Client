import 'dart:async';

import 'package:flutter/foundation.dart';

import 'core/engine/vpn_core_adapter.dart';
import 'core/engine/xray_adapter.dart';
import 'core/import/profile_detector.dart';
import 'core/model/pv_profile.dart';
import 'core/storage/profile_repository.dart';

enum PVLinkState { disconnected, connecting, connected, disconnecting, error }

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

/// Serializes native VPN lifecycle operations. Cancellation invalidates the
/// pending connection request immediately, but waits for an in-flight native
/// start to settle before stopping it; a stop must not race a late start.
/// Native start timeouts and hard process recovery are separate device gates.
class PVController extends ChangeNotifier {
  PVController(this.repository, {VpnCoreAdapter? primaryAdapter})
      : registry = EngineRegistry() {
    final adapter = primaryAdapter ?? XrayAdapter(repository: repository);
    registry.register(adapter);
    _defaultAdapter = adapter;
  }

  final ProfileRepository repository;
  final EngineRegistry registry;
  late final VpnCoreAdapter _defaultAdapter;
  VpnCoreAdapter? _activeAdapter;
  StreamSubscription<VpnCoreEvent>? _adapterSubscription;
  Timer? _statsTimer;
  Future<void> _operationTail = Future<void>.value();
  int _intentGeneration = 0;
  bool _disposed = false;

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

  /// Backwards compatible primary adapter; the live session may use another.
  VpnCoreAdapter? get adapter => _activeAdapter ?? _defaultAdapter;
  VpnCoreAdapter? get activeAdapter => _activeAdapter;

  bool get isBusy => linkState == PVLinkState.connecting ||
      linkState == PVLinkState.disconnecting;

  VpnCoreAdapter? adapterFor(PVProfile? profile) =>
      profile == null ? null : registry.forProfile(profile);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _serialize(Future<void> Function() task) {
    final result = _operationTail.then((_) => task());
    // A failed operation must not poison the queue of future operations.
    _operationTail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  bool _current(int generation) =>
      !_disposed && generation == _intentGeneration;

  Future<void> _listenTo(VpnCoreAdapter adapter, int generation) async {
    await _adapterSubscription?.cancel();
    _adapterSubscription = adapter.events.listen((event) {
      if (!_current(generation) || !identical(_activeAdapter, adapter)) return;
      // A start callback may report connected before external reachability
      // checks. This only describes core state, not data-path certification.
      linkState = switch (event.state) {
        VpnConnectionState.connected => PVLinkState.connected,
        VpnConnectionState.disconnected => PVLinkState.disconnected,
        VpnConnectionState.disconnecting => PVLinkState.disconnecting,
        VpnConnectionState.error => PVLinkState.error,
        _ => PVLinkState.connecting,
      };
      if (event.message != null) lastError = event.message;
      _notify();
    });
  }

  Future<void> load() async {
    final loaded = await repository.loadProfiles();
    profiles
      ..clear()
      ..addAll(loaded);
    selectedId = await repository.loadSelectedProfileId();
    if (selected == null && profiles.isNotEmpty) selectedId = profiles.first.id;
    _notify();
  }

  Future<void> addRaw(String value, {String source = 'text'}) async {
    final imported = detector.detect(value, sourceType: source).toProfile();
    final profile = await repository.secureImportedProfile(imported);
    profiles.insert(0, profile);
    selectedId ??= profile.id;
    await persist();
  }

  Future<void> select(String id) async {
    if (!profiles.any((p) => p.id == id)) return;
    selectedId = id;
    await repository.saveSelectedProfileId(id);
    _notify();
  }

  Future<void> switchProfile(String id) async {
    if (!profiles.any((p) => p.id == id) || id == selectedId) return;
    final shouldReconnect = linkState == PVLinkState.connected ||
        linkState == PVLinkState.connecting;
    if (_activeAdapter != null &&
        (shouldReconnect || linkState == PVLinkState.error)) {
      await disconnect();
    }
    // Never change the displayed selected node while the old tunnel still
    // owns native resources after a failed stop.
    if (_activeAdapter != null || linkState == PVLinkState.disconnecting) {
      return;
    }
    await select(id);
    if (shouldReconnect) await connect();
  }

  Future<void> remove(String id) async {
    if (selectedId == id &&
        (_activeAdapter != null || linkState != PVLinkState.disconnected)) {
      await disconnect();
      if (_activeAdapter != null || linkState != PVLinkState.disconnected) {
        // Keep the profile and its secrets while a failing native session
        // might still rely on them. The user can retry disconnect first.
        return;
      }
    }
    final target = profiles.where((p) => p.id == id).firstOrNull;
    profiles.removeWhere((p) => p.id == id);
    if (selectedId == id) {
      selectedId = profiles.isEmpty ? null : profiles.first.id;
    }
    // Avoid deleting secrets before the new selection is durable.
    await persist();
    if (target != null) {
      try {
        await repository.deleteProfileSecrets(target);
      } catch (_) {
        // Do not leave a removed profile active if the secret backend fails;
        // operator diagnostics can collect an explicit cleanup warning later.
      }
    }
  }

  Future<void> connect() {
    final profile = selected;
    if (profile == null || isBusy || linkState == PVLinkState.connected) {
      return Future<void>.value();
    }
    if (_activeAdapter != null) {
      lastError = 'A previous VPN session is still active or its cleanup failed. Disconnect it before starting another.';
      linkState = PVLinkState.error;
      _notify();
      return Future<void>.value();
    }
    final chosen = adapterFor(profile);
    if (chosen == null) {
      lastError = 'No enabled engine for "${profile.engineRequirements['engine'] ?? profile.protocol}".';
      linkState = PVLinkState.error;
      _notify();
      return Future<void>.value();
    }

    final generation = ++_intentGeneration;
    _activeAdapter = chosen;
    lastError = null;
    stats = null;
    linkState = PVLinkState.connecting;
    _notify();

    return _serialize(() async {
      try {
        if (!_current(generation)) return;
        await _listenTo(chosen, generation);
        if (!_current(generation)) return;
        final caps = await chosen.probeCapabilities();
        if (!_current(generation)) return;
        if (caps.protocols.isEmpty) {
          throw StateError('The ${caps.engine} is not available on this platform.');
        }
        final issues = await chosen.validateProfile(profile);
        if (!_current(generation)) return;
        if (issues.isNotEmpty) throw StateError(issues.join(' '));

        await chosen.start(profile);
        // Cancelling while native start is running invalidates its events.
        // The queued disconnect will now stop this exact adapter.
        if (!_current(generation)) return;
        // A returned start is not a proof of Internet connectivity.
        final state = await chosen.getState();
        if (!_current(generation)) return;
        if (state != VpnConnectionState.connected) {
          throw StateError('Native engine did not reach the connected state.');
        }
        linkState = PVLinkState.connected;
        _notify();
        _statsTimer?.cancel();
        _statsTimer = Timer.periodic(const Duration(seconds: 3), (_) {
          unawaited(refreshStats());
        });
      } catch (e) {
        if (!_current(generation)) return;
        lastError = e.toString();
        linkState = PVLinkState.error;
        _notify();
        await _adapterSubscription?.cancel();
        _adapterSubscription = null;
        try {
          await chosen.stop();
          _activeAdapter = null;
        } catch (_) {
          // Retain the active adapter so the user can retry a failed stop.
        }
        linkState = PVLinkState.error;
        _notify();
      }
    });
  }

  Future<void> disconnect() {
    if (linkState == PVLinkState.disconnected && _activeAdapter == null) {
      return Future<void>.value();
    }
    final generation = ++_intentGeneration;
    _statsTimer?.cancel();
    _statsTimer = null;
    stats = null;
    linkState = PVLinkState.disconnecting;
    _notify();
    return _serialize(() async {
      final session = _activeAdapter;
      String? stopError;
      try {
        if (session != null) await session.stop();
      } catch (e) {
        stopError = 'Unable to stop VPN core: $e';
      } finally {
        if (_current(generation)) {
          await _adapterSubscription?.cancel();
          _adapterSubscription = null;
          if (stopError == null) _activeAdapter = null;
          lastError = stopError;
          linkState = stopError == null ? PVLinkState.disconnected : PVLinkState.error;
          _notify();
        }
      }
    });
  }

  Future<void> toggle() =>
      linkState == PVLinkState.connected || linkState == PVLinkState.connecting
          ? disconnect()
          : connect();

  Future<void> refreshStats() async {
    final session = _activeAdapter;
    final generation = _intentGeneration;
    if (linkState != PVLinkState.connected || session == null) return;
    try {
      final newStats = await session.getStatistics();
      if (_current(generation) &&
          identical(_activeAdapter, session) &&
          linkState == PVLinkState.connected) {
        stats = newStats;
        _notify();
      }
    } catch (_) {
      // Diagnostic polling failures must not flip tunnel state.
    }
  }

  void clearError() {
    lastError = null;
    if (linkState == PVLinkState.error && _activeAdapter == null) {
      linkState = PVLinkState.disconnected;
    }
    _notify();
  }

  Future<void> persist() async {
    await repository.saveProfiles(profiles);
    await repository.saveSelectedProfileId(selectedId);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_intentGeneration;
    _statsTimer?.cancel();
    final subscription = _adapterSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }

  static final ProfileDetector detector = ProfileDetector();
}
