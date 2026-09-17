import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/core/import/profile_detector.dart';

void main() {
  final detector = ProfileDetector();

  test('VLESS reality', () {
    final r = detector.detect('vless://00000000-0000-0000-0000-000000000000@example.com:443?security=reality#Germany');
    expect(r.protocol, 'VLESS · REALITY');
    expect(r.endpoint, 'example.com:443');
    expect(r.security, 'reality');
    expect(r.engineRequirements['engine'], 'xray');
    expect(r.engineRequirements['protocols'], 'vless');
  });

  test('VLESS websocket transport normalization', () {
    final r = detector.detect('vless://uuid@1.2.3.4:443?type=ws&path=%2Fws&security=tls#edge');
    expect(r.transport, 'websocket');
    expect(r.security, 'tls');
  });

  test('VLESS raw without explicit type', () {
    final r = detector.detect('vless://uuid@1.2.3.4:80?security=none#plain');
    expect(r.transport, isNull);
    expect(r.security, 'none');
  });

  test('Trojan defaults to TLS security', () {
    final r = detector.detect('trojan://pass@t.example.com:443?type=grpc&serviceName=svc#trojan');
    expect(r.protocol, 'Trojan');
    expect(r.security, 'tls');
    expect(r.transport, 'grpc');
    expect(r.engineRequirements['protocols'], 'trojan');
  });

  test('Shadowsocks SIP002 base64 userinfo', () {
    final creds = base64.encode(utf8.encode('aes-256-gcm:secret-password'));
    final r = detector.detect('ss://$creds@ss.example.com:8388#SS');
    expect(r.protocol, 'Shadowsocks');
    expect(r.endpoint, 'ss.example.com:8388');
    expect(r.engineRequirements['protocols'], 'shadowsocks');
  });

  test('Hysteria2 requires the sing-box engine', () {
    final r = detector.detect('hysteria2://pass@hy2.example.com:443#HY2');
    expect(r.protocol, 'Hysteria2');
    expect(r.engineRequirements['engine'], 'sing-box');
    expect(r.engineRequirements['protocols'], 'hysteria2');
  });

  test('SOCKS scheme maps to xray engine', () {
    final r = detector.detect('socks5://user:pass@10.0.0.1:1080#local');
    expect(r.protocol, 'SOCKS5');
    expect(r.engineRequirements['engine'], 'xray');
  });

  test('VMess JSON payload fills transport/security', () {
    // {"v":"2","ps":"Berlin","add":"vm.example.com","port":"443","id":"uuid","net":"ws","tls":"tls"}
    const raw = 'vmess://eyJ2IjoiMiIsInBzIjoiQmVybGluIiwiYWRkIjoidm0uZXhhbXBsZS5jb20iLCJwb3J0IjoiNDQzIiwiaWQiOiJ1dWlkIiwibmV0Ijoid3MiLCJ0bHMiOiJ0bHMifQ==';
    final r = detector.detect(raw);
    expect(r.protocol, 'VMess');
    expect(r.name, 'Berlin');
    expect(r.transport, 'websocket');
    expect(r.security, 'tls');
    expect(r.engineRequirements['engine'], 'xray');
  });

  test('OpenVPN text', () {
    const raw = 'client\nproto udp\nremote vpn.example.com 1194\n<ca>\nDATA\n</ca>\n';
    final r = detector.detect(raw);
    expect(r.protocol, 'OpenVPN UDP');
    expect(r.endpoint, 'vpn.example.com:1194');
    expect(r.engineRequirements['engine'], 'openvpn');
  });

  test('WireGuard text', () {
    const raw = '[Interface]\nPrivateKey = sample\n[Peer]\nPublicKey = sample\nEndpoint = wg.example.com:51820\n';
    final r = detector.detect(raw);
    expect(r.protocol, 'WireGuard');
    expect(r.endpoint, 'wg.example.com:51820');
  });

  test('Clash YAML requires mihomo engine', () {
    const raw = 'proxies:\n  - name: a\n';
    final r = detector.detect(raw);
    expect(r.engineRequirements['engine'], 'mihomo');
  });

  test('unknown input fails', () {
    expect(() => detector.detect('hello world'), throwsFormatException);
  });
}
