import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/core/security/safe_error.dart';

void main() {
  test('redacts credential-bearing proxy and subscription links', () {
    const token = 'super-secret-token-123';
    const uuid = 'abc-def-123';
    final message = sanitizeVpnText(
      'error vless://$uuid@server.example:443?security=reality '
      'https://sub.example.com/$token '
      'token=$token password:topsecret',
    );
    expect(message, isNot(contains(token)));
    expect(message, isNot(contains(uuid)));
    expect(message, isNot(contains('topsecret')));
    expect(message, contains('[redacted-config-url]'));
  });

  test('platform exception must not show a credential-bearing message', () {
    final error = PlatformException(
      code: 'start-failed',
      message: 'https://provider.example.com/secret-session-token',
      details: 'password=private-information',
    );
    final safe = safeVpnError(error);
    expect(safe, isNot(contains('secret-session-token')));
    expect(safe, isNot(contains('private-information')));
    expect(safe, contains('startup'));
  });

  test('format exception source is never exposed', () {
    final error = FormatException(
      'bad token=secret-value',
      'vless://secret-uuid@host.example.com:443',
    );
    final safe = safeVpnError(error);
    expect(safe, isNot(contains('secret-value')));
    expect(safe, isNot(contains('secret-uuid')));
    expect(safe, contains('Invalid'));
  });

  test('timeouts never report a clean stopped VPN', () {
    final safe = safeVpnError(TimeoutException('password=secret-value'));
    expect(safe, contains('may still be active'));
    expect(safe, isNot(contains('secret-value')));
  });

  test('malformed native error codes cannot inject arbitrary content', () {
    final safe = safeVpnError(
      PlatformException(code: 'bad-code password=TOKENVALUE'),
    );
    expect(safe, contains('unknown'));
    expect(safe, isNot(contains('TOKENVALUE')));
  });

  test('unsafe raw private-key text is redacted', () {
    const privateKey = '-----BEGIN PRIVATE KEY-----\nTOPSECRET\n-----END PRIVATE KEY-----';
    final safe = sanitizeVpnText(privateKey);
    expect(safe, isNot(contains('TOPSECRET')));
    expect(safe, contains('[redacted-private-key]'));
  });
}
