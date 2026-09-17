import 'dart:async';

import '../model/pv_profile.dart';
import '../storage/profile_repository.dart';
import 'vpn_core_adapter.dart';
import 'xray_config_builder.dart';
import 'xray_mobile_binding.dart';

/// First-party Xray-core adapter. All platform interaction goes through
/// [XrayMobileBinding]; the adapter itself is pure Dart and unit-testable.
class XrayAdapter implements VpnCoreAdapter {
  XrayAdapter({
    XrayMobileBinding? binding,
    XrayConfigBuilder builder = const XrayConfigBuilder(),
    ProfileRepository? repository,
  })  : _binding = binding ?? (const MethodChannelXrayBinding()),
        _builder = builder,
        _repository = repository;

  final XrayMobileBinding _binding;
  final XrayConfigBuilder _builder;
  final ProfileRepository? _repository;

  final StreamController<VpnCoreEvent> _events = StreamController<VpnCoreEvent>.broadcast();
  VpnConnectionState _state = VpnConnectionState.disconnected;
  DateTime? _startedAt;
  int? _lastLatencyMs;
  String? _lastError;

  /// Control endpoint used by the host UI (generate_204 probe).
  static const probeUrl = 'https://www.gstatic.com/generate_204';

  @override
  String get id => 'xray-core';

  @override
  Stream<VpnCoreEvent> get events => _events.stream;

  VpnConnectionState get state => _state;

  void _transition(VpnConnectionState next, {String? message}) {
    _state = next;
    if (!_events.isClosed) _events.add(VpnCoreEvent(next, message: message));
  }

  bool _satisfiesRequirements(PVProfile profile) {
    final required = profile.engineRequirements['engine'];
    if (required == null || required.isEmpty) return true;
    return required == 'xray' || required == 'xray-json' || required == 'generic';
  }

  @override
  Future<VpnCoreCapabilities> probeCapabilities() async {
    if (!await _binding.isAvailable()) {
      return const VpnCoreCapabilities(
        engine: 'xray-core (native core unavailable)',
        protocols: <String>{},
        features: <String>{},
        version: 'unavailable',
      );
    }
    final version = await _binding.version();
    return VpnCoreCapabilities(
      engine: 'xray-core',
      protocols: Set<String>.from(XrayConfigBuilder.supportedProtocols),
      features: const <String>{'tun', 'stats', 'measureDelay', 'reality', 'shadowsocks'},
      version: version,
    );
  }

  @override
  Future<List<String>> validateProfile(PVProfile profile) async {
    final issues = <String>[];
    if (!_satisfiesRequirements(profile)) {
      issues.add(
          'Profile requires engine "${profile.engineRequirements['engine']}", which Xray cannot serve. Import it once a matching adapter is enabled.');
      return issues;
    }
    if (profile.engineRequirements['protocols'] case final needed?) {
      final supported = XrayConfigBuilder.supportedProtocols;
      final missing = needed.split(',').where((s) => s.trim().isNotEmpty && !supported.contains(s.trim())).toList();
      if (missing.isNotEmpty) issues.add('Protocol(s) not supported by Xray: ${missing.join(', ')}.');
    }
    try {
      final config = _builder.build(profile);
      if (!await _binding.validateConfig(config)) {
        issues.add('Xray rejected the generated configuration.');
      }
    } on FormatException catch (e) {
      issues.add(e.message);
    } catch (e) {
      issues.add('Validation failed: $e');
    }
    return issues;
  }

  @override
  Future<PVProfile> normalizeProfile(PVProfile profile) async {
    final repo = _repository;
    return repo == null ? profile : repo.resolveSecrets(profile);
  }

  @override
  Future<String> generateConfig(PVProfile profile) async => _builder.build(await normalizeProfile(profile));

  @override
  Future<void> start(PVProfile profile) async {
    if (_state == VpnConnectionState.connecting || _state == VpnConnectionState.connected) return;
    _lastError = null;
    _transition(VpnConnectionState.connecting);
    try {
      final resolved = await normalizeProfile(profile);
      final config = _builder.build(resolved);
      await _binding.start(config);
      _startedAt = DateTime.now();
      await _binding.resetStats();
      _transition(VpnConnectionState.connected);
    } catch (e) {
      _lastError = e.toString();
      _transition(VpnConnectionState.error, message: _lastError);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (_state == VpnConnectionState.disconnected) return;
    _transition(VpnConnectionState.disconnecting);
    try {
      await _binding.stop();
    } finally {
      _startedAt = null;
      _transition(VpnConnectionState.disconnected);
    }
  }

  @override
  Future<void> restart(PVProfile profile) async {
    await stop();
    await start(profile);
  }

  /// Measures the live proxy latency through the running core. Returns -1
  /// when the core is down or the probe fails.
  Future<int> measureDelay() async => _binding.measureDelay(probeUrl);

  @override
  Future<bool> healthCheck() async => await measureDelay() > 0;

  @override
  Future<VpnConnectionState> getState() async {
    final running = await _binding.isRunning();
    if (!running && _state == VpnConnectionState.connected) {
      _transition(VpnConnectionState.disconnected);
    }
    return _state;
  }

  @override
  Future<VpnCoreStatistics> getStatistics() async {
    final latency = _lastLatencyMs = await measureDelay();
    return VpnCoreStatistics(
      uploadBytes: await _binding.queryUplink(),
      downloadBytes: await _binding.queryDownlink(),
      startedAt: _startedAt,
      latencyMs: latency,
    );
  }

  @override
  Future<List<String>> getLogs() async => const <String>[];

  @override
  Future<Map<String, Object?>> collectDiagnostics() async {
    final caps = await probeCapabilities();
    return <String, Object?>{
      'adapter': id,
      'binding': _binding.bindingId,
      'engineVersion': caps.version,
      'nativeAvailable': caps.protocols.isNotEmpty,
      'state': _state.name,
      'lastError': _lastError,
      'startedAt': _startedAt?.toIso8601String(),
      'lastLatencyMs': _lastLatencyMs,
      'uplinkBytes': await _binding.queryUplink(),
      'downlinkBytes': await _binding.queryDownlink(),
    };
  }

  @override
  Future<String> getVersion() async {
    if (!await _binding.isAvailable()) return 'unavailable';
    return _binding.version();
  }

  Future<void> dispose() => _events.close();
}
