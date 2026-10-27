import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/controller.dart';
import 'package:vpn/core/engine/vpn_core_adapter.dart';
import 'package:vpn/core/model/pv_profile.dart';
import 'package:vpn/core/storage/profile_repository.dart';
import 'package:vpn/core/storage/secret_store.dart';

class MemoryRepository extends ProfileRepository {
  MemoryRepository() : super(secretStore: InMemorySecretStore());

  String? savedSelection;

  @override
  Future<void> saveSelectedProfileId(String? id) async {
    savedSelection = id;
  }

  @override
  Future<void> saveProfiles(List<PVProfile> profiles) async {}
}

class StubCore implements VpnCoreAdapter {
  StubCore(this.id);

  @override
  final String id;
  final StreamController<VpnCoreEvent> _events =
      StreamController<VpnCoreEvent>.broadcast();

  Completer<void>? startEntered;
  Completer<void>? releaseStart;
  Completer<VpnCoreStatistics>? statsResult;
  bool reportDisconnected = false;
  int startCalls = 0;
  int stopCalls = 0;
  VpnConnectionState state = VpnConnectionState.disconnected;

  @override
  Stream<VpnCoreEvent> get events => _events.stream;

  @override
  Future<VpnCoreCapabilities> probeCapabilities() async =>
      VpnCoreCapabilities(
        engine: id,
        protocols: const {'vless', 'wireguard'},
        features: const {'tun'},
        version: 'test',
      );

  @override
  Future<List<String>> validateProfile(PVProfile profile) async => [];

  @override
  Future<PVProfile> normalizeProfile(PVProfile profile) async => profile;

  @override
  Future<String> generateConfig(PVProfile profile) async => '{}';

  @override
  Future<void> start(PVProfile profile) async {
    startCalls++;
    state = VpnConnectionState.connecting;
    _events.add(const VpnCoreEvent(VpnConnectionState.connecting));
    final entered = startEntered;
    if (entered != null && !entered.isCompleted) entered.complete();
    await releaseStart?.future;
    state = VpnConnectionState.connected;
    _events.add(const VpnCoreEvent(VpnConnectionState.connected));
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    state = VpnConnectionState.disconnected;
    _events.add(const VpnCoreEvent(VpnConnectionState.disconnected));
  }

  @override
  Future<void> restart(PVProfile profile) async {
    await stop();
    await start(profile);
  }

  @override
  Future<bool> healthCheck() async => state == VpnConnectionState.connected;

  @override
  Future<VpnConnectionState> getState() async =>
      reportDisconnected ? VpnConnectionState.disconnected : state;

  @override
  Future<VpnCoreStatistics> getStatistics() async =>
      statsResult == null
          ? const VpnCoreStatistics(uploadBytes: 10, downloadBytes: 20)
          : statsResult!.future;

  @override
  Future<List<String>> getLogs() async => [];

  @override
  Future<Map<String, Object?>> collectDiagnostics() async => {};

  @override
  Future<String> getVersion() async => 'test';

  void emit(VpnConnectionState next) => _events.add(VpnCoreEvent(next));

  Future<void> dispose() => _events.close();
}

PVProfile fakeProfile(String id, String engine) => PVProfile(
      id: id,
      name: id,
      protocol: engine,
      sourceType: 'manual',
      rawSource: 'vless://example',
      createdAt: DateTime.utc(2026, 10, 27),
      engineRequirements: {'engine': engine},
    );

void main() {
  test('disconnect cancels a pending start; late connected event is ignored',
      () async {
    final core = StubCore('xray-core')
      ..startEntered = Completer<void>()
      ..releaseStart = Completer<void>();
    final controller = PVController(MemoryRepository(), primaryAdapter: core);
    controller.profiles.add(fakeProfile('one', 'xray'));
    controller.selectedId = 'one';

    final connecting = controller.connect();
    await core.startEntered!.future.timeout(const Duration(seconds: 10));
    final cancelling = controller.disconnect();
    expect(controller.linkState, PVLinkState.disconnecting);

    core.releaseStart!.complete();
    await Future.wait([connecting, cancelling]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.linkState, PVLinkState.disconnected);
    expect(controller.activeAdapter, isNull);
    expect(core.startCalls, 1);
    expect(core.stopCalls, 1);
    core.emit(VpnConnectionState.connected);
    await Future<void>.delayed(Duration.zero);
    expect(controller.linkState, PVLinkState.disconnected);
    controller.dispose();
    await core.dispose();
  });

  test('switching between engines stops exactly the old adapter', () async {
    final xray = StubCore('xray-core');
    final wireguard = StubCore('wireguard');
    final repo = MemoryRepository();
    final controller = PVController(repo, primaryAdapter: xray);
    controller.registry.register(wireguard);
    controller.profiles.addAll([
      fakeProfile('x', 'xray'),
      fakeProfile('w', 'wireguard'),
    ]);
    controller.selectedId = 'x';

    await controller.connect();
    expect(controller.activeAdapter, same(xray));
    await controller.switchProfile('w');
    expect(repo.savedSelection, 'w');
    expect(controller.activeAdapter, same(wireguard));
    expect(xray.stopCalls, 1);
    expect(wireguard.startCalls, 1);
    xray.emit(VpnConnectionState.error);
    await Future<void>.delayed(Duration.zero);
    expect(controller.linkState, PVLinkState.connected);

    await controller.disconnect();
    expect(wireguard.stopCalls, 1);
    expect(xray.stopCalls, 1);
    expect(controller.linkState, PVLinkState.disconnected);
    controller.dispose();
    await xray.dispose();
    await wireguard.dispose();
  });

  test('late traffic sample does not survive disconnect', () async {
    final core = StubCore('xray-core')
      ..statsResult = Completer<VpnCoreStatistics>();
    final controller = PVController(MemoryRepository(), primaryAdapter: core);
    controller.profiles.add(fakeProfile('one', 'xray'));
    controller.selectedId = 'one';
    await controller.connect();
    final sample = controller.refreshStats();
    await controller.disconnect();
    core.statsResult!.complete(const VpnCoreStatistics(uploadBytes: 1000));
    await sample;
    expect(controller.stats, isNull);
    expect(controller.linkState, PVLinkState.disconnected);
    controller.dispose();
    await core.dispose();
  });

  test('does not assert connected if the native core reports disconnected',
      () async {
    final core = StubCore('xray-core')..reportDisconnected = true;
    final controller = PVController(MemoryRepository(), primaryAdapter: core);
    controller.profiles.add(fakeProfile('one', 'xray'));
    controller.selectedId = 'one';
    await controller.connect();
    expect(controller.linkState, PVLinkState.error);
    expect(controller.lastError, contains('did not reach'));
    expect(core.stopCalls, 1);
    controller.dispose();
    await core.dispose();
  });
}
