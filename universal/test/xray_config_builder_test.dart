import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/core/engine/xray_config_builder.dart';
import 'package:vpn/core/model/pv_profile.dart';

PVProfile profile(String raw, {String? dnsPolicy, String? routingPolicy}) => PVProfile(
      id: 't',
      name: 't',
      protocol: 't',
      sourceType: 'text',
      rawSource: raw,
      createdAt: DateTime.utc(2026, 1, 1),
      dnsPolicy: dnsPolicy,
      routingPolicy: routingPolicy,
    );

Map<String, dynamic> parse(PVProfile p) => jsonDecode(const XrayConfigBuilder().build(p)) as Map<String, dynamic>;

void main() {
  const builder = XrayConfigBuilder();

  test('VLESS REALITY outbound + stream settings', () {
    final cfg = parse(profile(
      'vless://uuid@h.example.com:443?security=reality&sni=www.example.com&pbk=PUBKEY&sid=ab&fp=chrome&type=grpc&serviceName=gun',
    ));
    final out = cfg['outbounds'].first;
    expect(out['protocol'], 'vless');
    expect(out['settings']['id'], 'uuid');
    final stream = out['streamSettings'];
    expect(stream['method'], 'grpc');
    expect(stream['security'], 'reality');
    expect(stream['realitySettings']['serverName'], 'www.example.com');
    expect(stream['realitySettings']['password'], 'PUBKEY');
    expect(stream['realitySettings']['shortId'], 'ab');
  });

  test('VLESS websocket TLS', () {
    final cfg = parse(profile('vless://uuid@h:443?security=tls&sni=h.example.com&type=ws&path=%2Fws&host=h.example.com'));
    final stream = cfg['outbounds'].first['streamSettings'];
    expect(stream['method'], 'websocket');
    expect(stream['wsSettings']['path'], '/ws');
    expect(stream['tlsSettings']['serverName'], 'h.example.com');
  });

  test('VMess raw TCP', () {
    final payload = base64.encode(utf8.encode(
        '{"v":"2","ps":"v","add":"vm.example.com","port":"443","id":"uuid","net":"tcp","tls":"tls","scy":"auto"}'));
    final cfg = parse(profile('vmess://$payload'));
    final out = cfg['outbounds'].first;
    expect(out['protocol'], 'vmess');
    expect(out['settings']['security'], 'auto');
    expect(out['streamSettings']['method'], 'raw');
    expect(out['streamSettings']['security'], 'tls');
  });

  test('Trojan with mux', () {
    final cfg = parse(profile('trojan://pw@t.example.com:443'));
    final out = cfg['outbounds'].first;
    expect(out['protocol'], 'trojan');
    expect(out['mux']['enabled'], true);
    expect(out['streamSettings']['security'], 'tls');
  });

  test('Shadowsocks SIP002', () {
    final creds = base64.encode(utf8.encode('aes-256-gcm:pw'));
    final cfg = parse(profile('ss://$creds@ss.example.com:8388#s'));
    final out = cfg['outbounds'].first;
    expect(out['protocol'], 'shadowsocks');
    expect(out['settings']['method'], 'aes-256-gcm');
    expect(out['settings']['password'], 'pw');
    expect(out['settings']['port'], 8388);
  });

  test('Shadowsocks legacy fully-base64 URI', () {
    final inner = 'chacha20-ietf-poly1305:legacy@10.0.0.2:9999';
    final cfg = parse(profile('ss://${base64.encode(utf8.encode(inner))}#legacy'));
    final out = cfg['outbounds'].first;
    expect(out['protocol'], 'shadowsocks');
    expect(out['settings']['method'], 'chacha20-ietf-poly1305');
    expect(out['settings']['address'], '10.0.0.2');
    expect(out['settings']['port'], 9999);
  });

  test('Shadowsocks plugin is refused, not mis-generated', () {
    final creds = base64.encode(utf8.encode('aes-256-gcm:pw'));
    expect(
      () => builder.build(profile('ss://$creds@h:8388?plugin=obfs-local%3Bobfs%3Dhttp')),
      throwsFormatException,
    );
  });

  test('SOCKS outbound with credentials', () {
    final cfg = parse(profile('socks5://user:pass@10.0.0.3:1080'));
    final server = cfg['outbounds'].first['settings']['servers'].first;
    expect(cfg['outbounds'].first['protocol'], 'socks');
    expect(server['address'], '10.0.0.3');
    expect(server['port'], 1080);
    expect(server['users'].first['user'], 'user');
  });

  test('HTTP(S) proxy outbound', () {
    final cfg = parse(profile('https://user:pw@corp.example.com:3128'));
    final out = cfg['outbounds'].first;
    expect(out['protocol'], 'http');
    expect(out['streamSettings']['security'], 'tls');
  });

  test('stats + policy blocks enable traffic counters', () {
    final cfg = parse(profile('trojan://pw@t.example.com:443'));
    expect(cfg['stats'], isEmpty);
    expect(cfg['policy']['levels']['0']['statsUserUplink'], isTrue);
    expect(cfg['policy']['system']['statsOutboundDownlink'], isTrue);
  });

  test('default DNS is IP-hosted DoH and hijacks port 53', () {
    final cfg = parse(profile('trojan://pw@t.example.com:443'));
    expect(cfg['dns']['servers'], contains('https://8.8.8.8/dns-query'));
    final hijack = (cfg['routing']['rules'] as List).firstWhere((r) => r['port'] == 53);
    expect(hijack['outboundTag'], 'dns-out');
  });

  test('dnsPolicy system/cloudflare/off variants', () {
    expect(parse(profile('trojan://pw@t:443', dnsPolicy: 'system'))['dns']['servers'], ['localhost']);
    final cf = parse(profile('trojan://pw@t:443', dnsPolicy: 'cloudflare'));
    expect(cf['dns']['servers'], contains('https://cloudflare-dns.com/dns-query'));
    expect(cf['outbounds'].where((o) => o['tag'] == 'dns-out'), isNotEmpty);
    final off = parse(profile('trojan://pw@t:443', dnsPolicy: 'off'));
    expect(off.containsKey('dns'), isFalse);
    expect(off['outbounds'].where((o) => o['tag'] == 'dns-out'), isEmpty);
  });

  test('routing keeps private ranges direct; bypassIR adds geoip:ir', () {
    final base = parse(profile('trojan://pw@t:443'));
    final rules = (base['routing']['rules'] as List).cast<Map>();
    expect(rules.any((r) => r['outboundTag'] == 'direct' && (r['ip'] as List).contains('192.168.0.0/16')), isTrue);
    expect(rules.any((r) => (r['ip'] as List?)?.contains('geoip:ir') == true), isFalse);

    final ir = parse(profile('trojan://pw@t:443', routingPolicy: 'bypassIR'));
    final irRules = (ir['routing']['rules'] as List).cast<Map>();
    expect(irRules.any((r) => (r['ip'] as List?)?.contains('geoip:ir') == true), isTrue);
  });

  test('non-Xray protocols are refused with an engine hint', () {
    const wg = '[Interface]\nPrivateKey = a\n[Peer]\nPublicKey = b\nEndpoint = h:1\n';
    expect(
      () => builder.build(PVProfile(
            id: 'x',
            name: 'x',
            protocol: 'WireGuard',
            sourceType: 'text',
            rawSource: wg,
            createdAt: DateTime.utc(2026, 1, 1),
            engineRequirements: {'engine': 'wireguard'},
          )),
      throwsFormatException,
    );
  });
}
