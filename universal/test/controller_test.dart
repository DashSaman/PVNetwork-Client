import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/controller.dart';
import 'package:vpn/core/engine/vpn_core_adapter.dart';
import 'package:vpn/core/engine/xray_adapter.dart';
import 'package:vpn/core/engine/xray_mobile_binding.dart';
import 'package:vpn/core/model/pv_profile.dart';
import 'package:vpn/core/storage/profile_repository.dart';
import 'package:vpn/core/storage/secret_store.dart';

class FakeBinding implements XrayMobileBinding {
  bool started = false;
  bool available = true;
  int startCalls = 0;
  int stopCalls = 0;
  int? simulatedLatency;
  int delayProbeCalls = 0;
  bool failAfterStart = false;
  bool failStop = false;
  bool failResetStats = false;

  @override
  String get bindingId => 'fake';

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String> version() async => available ? 'v-test' : throw StateError('unavailable');

  @override
  Future<bool> validateConfig(String config) async => available && config.isNotEmpty;

  @override
  Future<bool> prepare() async => true;

  @override
  Future<void> start(String config, {int tunFd = -1}) async {
    if (!available) throw StateError('native core missing');
    startCalls++;
    started = true;
    if (failAfterStart) throw StateError('partially initialized');
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    if (failStop) throw StateError('native stop failed');
    started = false;
  }

  @override
  Future<bool> isRunning() async => started;

  @override
  Future<int> queryUplink() async => started ? 100 : 0;

  @override
  Future<int> queryDownlink() async => started ? 900 : 0;

  @override
  Future<void> resetStats() async {
    if (failResetStats) throw StateError('stats unavailable');
  }

  @override
  Future<int> measureDelay(String url) async {
    delayProbeCalls++;
    return started ? (simulatedLatency ?? 42) : -1;
  }

  @override
  Future<void> initEnvironment(String assetLocation, String configLocation) async {}
}

PVProfile vlessProfile() => PVProfile(
      id: 'v1',
      name: 'VLESS',
      protocol: 'VLESS',
      sourceType: 'text',
      rawSource: 'vless://uuid@h.example.com:443?security=reality&sni=www.example.com&pbk=K&sid=ab&type=raw',
      createdAt: DateTime.utc(2026, 1, 1),
      endpoint: 'h.example.com:443',
      engineRequirements: const {'engine': 'xray', 'protocols': 'vless'},
    );

void main() {
  test('controller refuses profiles whose engine has no adapter', () async {
    final controller = PVController(ProfileRepository(secretStore: InMemorySecretStore()));
    final unsupported = vlessProfile().copyWith(
      engineRequirements: const {'engine': 'wireguard', 'protocols': 'wireguard'},
    );
    controller.profiles.add(unsupported);
    controller.selectedId = unsupported.id;
    await controller.connect();
    expect(controller.linkState, PVLinkState.error);
    expect(controller.lastError, contains('wireguard'));
    controller.dispose();
  });

  test('engine registry maps canonical engines', () {
    final controller = PVController(ProfileRepository(secretStore: InMemorySecretStore()));
    final xray = controller.adapter!;
    expect(controller.registry['xray-core'], same(xray));
    expect(controller.registry.forProfile(vlessProfile()), same(xray));

    final wg = vlessProfile().copyWith(engineRequirements: const {'engine': 'wireguard'});
    expect(controller.registry.forProfile(wg), isNull);

    final json = vlessProfile().copyWith(engineRequirements: const {'engine': 'xray-json'});
    expect(controller.registry.forProfile(json), same(xray));
    controller.dispose();
  });

  test('adapter start/stop drives event stream and statistics', () async {
    final binding = FakeBinding();
    // Direct adapter test with an injected binding.
    final adapter = xrayAdapterForTest(binding);
    final events = <VpnConnectionState>[];
    final sub = adapter.events.listen((e) => events.add(e.state));

    await adapter.start(vlessProfile());
    expect(binding.started, isTrue);
    expect(binding.startCalls, 1);

    final stats = await adapter.getStatistics();
    expect(stats.uploadBytes, 100);
    expect(stats.downloadBytes, 900);
    expect(stats.latencyMs, 42);

    await adapter.stop();
    expect(binding.stopCalls, 1);
    await Future<void>.delayed(Duration.zero);
    expect(events, contains(VpnConnectionState.connected));
    expect(events, contains(VpnConnectionState.disconnected));
    await sub.cancel();
    await adapter.dispose();
  });

  test('stats polling coalesces core HTTPS probe to at most once per 30 seconds', () async {
    final binding = FakeBinding();
    final adapter = xrayAdapterForTest(binding);
    await adapter.start(vlessProfile());
    for (var i = 0; i < 5; i++) {
      final stats = await adapter.getStatistics();
      expect(stats.latencyMs, 42);
    }
    expect(binding.delayProbeCalls, 1,
        reason: '3-second stats refreshes must not generate 3-second HTTPS probes');
    await adapter.stop();
    await adapter.start(vlessProfile());
    await adapter.getStatistics();
    expect(binding.delayProbeCalls, 2,
        reason: 'a new VPN session must measure fresh outbound latency');
    await adapter.stop();
    await adapter.dispose();
  });

  test('native running state is healthy even with unavailable probe delay', () async {
    final binding = FakeBinding()..simulatedLatency = -1;
    final adapter = xrayAdapterForTest(binding);
    await adapter.start(vlessProfile());
    expect(await adapter.healthCheck(), isTrue);
    final stats = await adapter.getStatistics();
    expect(stats.latencyMs, isNull);
    await adapter.stop();
    expect(await adapter.healthCheck(), isFalse);
    await adapter.dispose();
  });

  test('partial native start failure invokes stop for cleanup', () async {
    final binding = FakeBinding()..failAfterStart = true;
    final adapter = xrayAdapterForTest(binding);
    await expectLater(adapter.start(vlessProfile()), throwsStateError);
    expect(binding.stopCalls, 1);
    expect(binding.started, isFalse);
    expect(adapter.state, VpnConnectionState.error);
    await adapter.dispose();
  });

  test('stop failure must not claim disconnected', () async {
    final binding = FakeBinding();
    final adapter = xrayAdapterForTest(binding);
    await adapter.start(vlessProfile());
    binding.failStop = true;
    await expectLater(adapter.stop(), throwsStateError);
    expect(adapter.state, VpnConnectionState.error);
    expect(binding.started, isTrue);
    binding.failStop = false;
    await adapter.stop();
    expect(adapter.state, VpnConnectionState.disconnected);
    await adapter.dispose();
  });

  test('unavailable statistics reset does not break running session', () async {
    final binding = FakeBinding()..failResetStats = true;
    final adapter = xrayAdapterForTest(binding);
    await adapter.start(vlessProfile());
    expect(binding.started, isTrue);
    expect(adapter.state, VpnConnectionState.connected);
    await adapter.stop();
    await adapter.dispose();
  });

  test('adapter reports unavailable core honestly', () async {
    final adapter = xrayAdapterForTest(FakeBinding()..available = false);
    final caps = await adapter.probeCapabilities();
    expect(caps.protocols, isEmpty);
    expect(caps.version, 'unavailable');
  });
}

/// Exposes the adapter constructor with a custom binding for tests.
XrayAdapter xrayAdapterForTest(XrayMobileBinding binding) => XrayAdapter(binding: binding);
