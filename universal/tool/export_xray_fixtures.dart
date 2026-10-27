// Generates synthetic PVNetwork client configs for validation with the
// ACTUAL pinned Xray-core, rather than trusting shape-only Dart unit tests.
//
// Usage from generated Flutter buildhost:
//   dart run tool/export_xray_fixtures.dart ../core/xray-mobile/config-fixtures
//
// Data below are synthetic/non-working identities. No user configurations,
// subscription tokens or real credentials are included in CI artifacts.
import 'dart:convert';
import 'dart:io';

import 'package:vpn/core/engine/xray_config_builder.dart';
import 'package:vpn/core/model/pv_profile.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: export_xray_fixtures.dart OUTPUT_DIR');
    exitCode = 2;
    return;
  }
  final dir = Directory(args.single)..createSync(recursive: true);
  const id = '00000000-0000-4000-8000-000000000001';
  final key = base64Url.encode(List<int>.generate(32, (i) => i + 1)).replaceAll('=', '');
  final vmessPayload = base64.encode(utf8.encode(jsonEncode({
    'v': '2',
    'ps': 'CI synthetic',
    'add': 'vm.example.com',
    'port': '443',
    'id': id,
    'net': 'ws',
    'host': 'cdn.example.com',
    'path': '/ws',
    'tls': 'tls',
    'sni': 'cdn.example.com',
    'scy': 'auto',
  })));
  final ssUser = base64.encode(utf8.encode('aes-256-gcm:synthetic-password'));

  final samples = <String, String>{
    'vless-reality.json':
        'vless://$id@vpn.example.com:443?security=reality&flow=xtls-rprx-vision&sni=www.example.com&pbk=$key&sid=0123456789abcdef&fp=chrome&type=raw',
    'vless-ws-tls.json':
        'vless://$id@vpn.example.com:443?security=tls&sni=cdn.example.com&type=ws&host=cdn.example.com&path=%2Fws',
    'vmess-ws-tls.json': 'vmess://$vmessPayload',
    'trojan-tls.json': 'trojan://synthetic-password@vpn.example.com:443?security=tls&type=raw',
    'shadowsocks-aead.json': 'ss://$ssUser@vpn.example.com:8388',
    'socks5-auth.json': 'socks5://user:pass@192.168.1.10:1080',
    'https-proxy-auth.json': 'https://user:pass@proxy.example.com:3128',
  };

  for (final sample in samples.entries) {
    final profile = PVProfile(
      id: sample.key,
      name: sample.key,
      protocol: sample.key.split('-').first,
      sourceType: 'test-fixture',
      rawSource: sample.value,
      createdAt: DateTime.utc(2026, 10, 27),
    );
    final config = const XrayConfigBuilder().build(profile);
    final parsed = jsonDecode(config);
    if (parsed is! Map || parsed['outbounds'] is! List ||
        parsed['inbounds'] is! List) {
      throw StateError('Invalid generated Xray config structure: ${sample.key}');
    }
    final target = File('${dir.path}/${sample.key}');
    target.writeAsStringSync(config);
  }
  stdout.writeln('Generated ${samples.length} synthetic Xray fixtures for core validation.');
}
