import '../model/pv_profile.dart';

enum VpnConnectionState {
  disconnected,
  preparing,
  requestingPermission,
  connecting,
  authenticating,
  establishingTunnel,
  connected,
  reconnecting,
  disconnecting,
  error,
}

class VpnCoreCapabilities {
  const VpnCoreCapabilities({
    required this.engine,
    required this.protocols,
    required this.features,
    required this.version,
  });

  final String engine;
  final Set<String> protocols;
  final Set<String> features;
  final String version;

  bool supportsProtocol(String protocol) => protocols.contains(protocol.toLowerCase());
  bool supportsFeature(String feature) => features.contains(feature.toLowerCase());
}

class VpnCoreStatistics {
  const VpnCoreStatistics({
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.startedAt,
    this.latencyMs,
  });

  final int uploadBytes;
  final int downloadBytes;
  final DateTime? startedAt;
  final int? latencyMs;
}

class VpnCoreEvent {
  const VpnCoreEvent(this.state, {this.message, this.diagnosticId});
  final VpnConnectionState state;
  final String? message;
  final String? diagnosticId;
}

abstract interface class VpnCoreAdapter {
  String get id;

  Stream<VpnCoreEvent> get events;

  Future<VpnCoreCapabilities> probeCapabilities();
  Future<List<String>> validateProfile(PVProfile profile);
  Future<PVProfile> normalizeProfile(PVProfile profile);
  Future<String> generateConfig(PVProfile profile);
  Future<void> start(PVProfile profile);
  Future<void> stop();
  Future<void> restart(PVProfile profile);
  Future<bool> healthCheck();
  Future<VpnConnectionState> getState();
  Future<VpnCoreStatistics> getStatistics();
  Future<List<String>> getLogs();
  Future<Map<String, Object?>> collectDiagnostics();
  Future<String> getVersion();
}
