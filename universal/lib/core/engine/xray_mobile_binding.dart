import 'package:flutter/services.dart';

/// Native-side binding to the first-party `pvxray` gomobile core.
///
/// Contract (MethodChannel `dev.pvnetwork.xray`, standard codec):
/// - version                  -> String
/// - validate(config)         -> bool (throws PlatformException when invalid)
/// - start(config, tunFd)     -> void (tunFd < 0 lets the host resolve the fd)
/// - stop                     -> void
/// - isRunning                -> bool
/// - queryUplink              -> int
/// - queryDownlink            -> int
/// - resetStats               -> void
/// - measureDelay(url)        -> int (ms, -1 on failure)
/// - initEnvironment(assets, configDir) -> void
abstract interface class XrayMobileBinding {
  String get bindingId;

  Future<bool> isAvailable();
  Future<String> version();
  Future<bool> validateConfig(String config);

  /// Requests the platform VPN permission when needed (Android dialog) and
  /// returns whether the tunnel may start. Desktop platforms report true.
  Future<bool> prepare();
  Future<void> start(String config, {int tunFd});
  Future<void> stop();
  Future<bool> isRunning();
  Future<int> queryUplink();
  Future<int> queryDownlink();
  Future<void> resetStats();
  Future<int> measureDelay(String url);
  Future<void> initEnvironment(String assetLocation, String configLocation);
}

class MethodChannelXrayBinding implements XrayMobileBinding {
  const MethodChannelXrayBinding({
    this.channel = _channel,
    this.startTimeout = nativeStartTimeout,
    this.stopTimeout = nativeStopTimeout,
  });

  static const _channel = MethodChannel('dev.pvnetwork.xray');
  final MethodChannel channel;
  final Duration startTimeout;
  final Duration stopTimeout;

  @override
  String get bindingId => 'method-channel';

  @override
  Future<bool> isAvailable() async {
    try {
      await version();
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<String> version() async => (await channel.invokeMethod<String>('version')) ?? '';

  @override
  Future<bool> validateConfig(String config) async {
    try {
      return (await channel.invokeMethod<bool>('validate', {'config': config})) ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Timeout bounds Flutter's wait for the native service. It does not
  /// forcibly terminate native Go calls; the Android worker must clean up
  /// once those calls return. Never interpret a timeout as DISCONNECTED.
  static const nativeStartTimeout = Duration(seconds: 25);
  static const nativeStopTimeout = Duration(seconds: 12);

  Future<void> _invokeStart(String config, int tunFd) async {
    await channel
        .invokeMethod<void>('start', {'config': config, 'tunFd': tunFd})
        .timeout(startTimeout);
  }

  @override
  Future<void> start(String config, {int tunFd = -1}) async {
    try {
      await _invokeStart(config, tunFd);
    } on PlatformException catch (e) {
      if (e.code == 'vpn-permission') {
        // Permission UI can remain open until the user decides. Only the
        // native startup after permission is bounded.
        final granted = await prepare();
        if (!granted) {
          throw StateError('VPN permission was denied; the tunnel cannot start.');
        }
        await _invokeStart(config, tunFd);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<bool> prepare() async => (await channel.invokeMethod<bool>('prepare')) ?? false;

  @override
  Future<void> stop() =>
      channel.invokeMethod<void>('stop').timeout(stopTimeout);

  @override
  Future<bool> isRunning() async => (await channel.invokeMethod<bool>('isRunning')) ?? false;

  @override
  Future<int> queryUplink() async => (await channel.invokeMethod<int>('queryUplink')) ?? 0;

  @override
  Future<int> queryDownlink() async => (await channel.invokeMethod<int>('queryDownlink')) ?? 0;

  @override
  Future<void> resetStats() => channel.invokeMethod<void>('resetStats');

  @override
  Future<int> measureDelay(String url) async => (await channel.invokeMethod<int>('measureDelay', {'url': url})) ?? -1;

  @override
  Future<void> initEnvironment(String assetLocation, String configLocation) =>
      channel.invokeMethod<void>('initEnvironment', {'assets': assetLocation, 'config': configLocation});
}

/// Fallback for platforms without the native pvxray handler: every call
/// reports an unavailable engine instead of crashing.
class UnavailableXrayBinding implements XrayMobileBinding {
  const UnavailableXrayBinding();

  static const _reason = 'pvxray native core is not available on this platform';

  @override
  String get bindingId => 'unavailable';

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<String> version() async => 'unavailable';

  @override
  Future<bool> validateConfig(String config) => Future.value(false);

  @override
  Future<bool> prepare() => Future.value(false);

  @override
  Future<void> start(String config, {int tunFd = -1}) => Future.error(StateError(_reason));

  @override
  Future<void> stop() => Future.error(StateError(_reason));

  @override
  Future<bool> isRunning() => Future.value(false);

  @override
  Future<int> queryUplink() => Future.value(0);

  @override
  Future<int> queryDownlink() => Future.value(0);

  @override
  Future<void> resetStats() async {}

  @override
  Future<int> measureDelay(String url) => Future.value(-1);

  @override
  Future<void> initEnvironment(String assetLocation, String configLocation) async {}
}
