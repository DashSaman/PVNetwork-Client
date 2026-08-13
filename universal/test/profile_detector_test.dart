import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/core/import/profile_detector.dart';

void main() {
  final detector = ProfileDetector();

  test('VLESS reality', () {
    final r = detector.detect('vless://00000000-0000-0000-0000-000000000000@example.com:443?security=reality#Germany');
    expect(r.protocol, 'VLESS · REALITY');
    expect(r.endpoint, 'example.com:443');
  });

  test('OpenVPN text', () {
    const raw = 'client\nproto udp\nremote vpn.example.com 1194\n<ca>\nDATA\n</ca>\n';
    final r = detector.detect(raw);
    expect(r.protocol, 'OpenVPN UDP');
    expect(r.endpoint, 'vpn.example.com:1194');
  });

  test('WireGuard text', () {
    const raw = '[Interface]\nPrivateKey = sample\n[Peer]\nPublicKey = sample\nEndpoint = wg.example.com:51820\n';
    final r = detector.detect(raw);
    expect(r.protocol, 'WireGuard');
    expect(r.endpoint, 'wg.example.com:51820');
  });

  test('unknown input fails', () {
    expect(() => detector.detect('hello world'), throwsFormatException);
  });
}
