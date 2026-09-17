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
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    started = false;
  }

  @override
  Future<bool> isRunning() async => started;

  @override
  Future<int> queryUplink() async => started ? 100 : 0;

  @override
  Future<int> queryDownlink() async => started ? 900 : 0;

  @override
  Future<void> resetStats() async {}

  @override
  Future<int> measureDelay(String url) async => started ? 42 : -1;

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

  test('adapter reports unavailable core honestly', () async {
    final adapter = xrayAdapterForTest(FakeBinding()..available = false);
    final caps = await adapter.probeCapabilities();
    expect(caps.protocols, isEmpty);
    expect(caps.version, 'unavailable');
  });
}

/// Exposes the adapter constructor with a custom binding for tests.
XrayAdapter xrayAdapterForTest(XrayMobileBinding binding) => XrayAdapter(binding: binding);
