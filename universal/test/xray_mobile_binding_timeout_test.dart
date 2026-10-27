import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/core/engine/xray_mobile_binding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.pvnetwork.xray.timeout-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('stop completes only after native method reply is received', () async {
    final reply = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'stop') {
        await reply.future;
        return true;
      }
      throw MissingPluginException('Unexpected method');
    });

    const binding = MethodChannelXrayBinding(
      channel: channel,
      stopTimeout: Duration(milliseconds: 250),
    );
    var completed = false;
    final pending = binding.stop().then((_) { completed = true; });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(completed, isFalse);
    reply.complete();
    await pending;
    expect(completed, isTrue);
  });

  test('stop timeout does not claim a native stop succeeded', () async {
    final held = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'stop') {
        await held.future;
        return true;
      }
      return null;
    });
    const binding = MethodChannelXrayBinding(
      channel: channel,
      stopTimeout: Duration(milliseconds: 30),
    );
    await expectLater(binding.stop(), throwsA(isA<TimeoutException>()));
    held.complete();
  });

  test('native start wait is bounded but user VPN permission is retryable',
      () async {
    var starts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'start') {
        starts++;
        if (starts == 1) {
          throw PlatformException(code: 'vpn-permission', message: 'required');
        }
        return true;
      }
      if (call.method == 'prepare') return true;
      return null;
    });
    const binding = MethodChannelXrayBinding(
      channel: channel,
      startTimeout: Duration(milliseconds: 250),
    );
    await binding.start('{}');
    expect(starts, 2);
  });

  test('stalled core start returns TimeoutException to the controller',
      () async {
    final held = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'start') {
        await held.future;
        return true;
      }
      return null;
    });
    const binding = MethodChannelXrayBinding(
      channel: channel,
      startTimeout: Duration(milliseconds: 30),
    );
    await expectLater(binding.start('{}'), throwsA(isA<TimeoutException>()));
    held.complete();
  });
}
