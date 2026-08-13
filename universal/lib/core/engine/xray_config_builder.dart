import 'dart:convert';
import '../model/pv_profile.dart';

class XrayConfigBuilder {
  const XrayConfigBuilder();
  static const healthPort = 19670;

  String build(PVProfile p) {
    final cfg = <String, dynamic>{
      'log': {'loglevel': 'warning'},
      'inbounds': [
        {'tag': 'tun-in', 'protocol': 'tun', 'settings': {'mtu': 1500, 'userLevel': 0}},
        {'tag': 'health-in', 'listen': '127.0.0.1', 'port': healthPort, 'protocol': 'http', 'settings': {}},
      ],
      'outbounds': [_outbound(p), {'tag': 'direct', 'protocol': 'freedom', 'settings': {}}, {'tag': 'block', 'protocol': 'blackhole', 'settings': {}}],
    };
    return const JsonEncoder.withIndent('  ').convert(cfg);
  }

  Map<String, dynamic> _outbound(PVProfile p) {
    final raw = p.rawSource.trim();
    if (raw.startsWith('vless://')) return _vless(Uri.parse(raw));
    if (raw.startsWith('trojan://')) return _trojan(Uri.parse(raw));
    if (raw.startsWith('vmess://')) return _vmess(raw);
    throw FormatException('Xray config generation is not enabled for ${p.protocol}.');
  }

  Map<String, dynamic> _vless(Uri u) {
    final q = u.queryParameters;
    final id = Uri.decodeComponent(u.userInfo);
    if (u.host.isEmpty || !u.hasPort || id.isEmpty) throw const FormatException('Incomplete VLESS profile.');
    final security = (q['security'] ?? 'none').toLowerCase();
    return {
      'tag': 'proxy',
      'protocol': 'vless',
      'settings': {'address': u.host, 'port': u.port, 'id': id, 'encryption': q['encryption'] ?? 'none', if ((q['flow'] ?? '').isNotEmpty) 'flow': q['flow'], 'level': 0},
      'streamSettings': _stream(u, security),
    };
  }

  Map<String, dynamic> _trojan(Uri u) {
    final password = Uri.decodeComponent(u.userInfo);
    if (u.host.isEmpty || !u.hasPort || password.isEmpty) throw const FormatException('Incomplete Trojan profile.');
    final security = (u.queryParameters['security'] ?? 'tls').toLowerCase();
    if (security == 'none') throw const FormatException('Trojan requires verified transport security.');
    return {
      'tag': 'proxy',
      'protocol': 'trojan',
      'settings': {'address': u.host, 'port': u.port, 'password': password, 'level': 0},
      'streamSettings': _stream(u, security),
      'mux': {'enabled': true, 'concurrency': 8},
    };
  }

  Map<String, dynamic> _vmess(String raw) {
    final payload = raw.substring(8).split('#').first;
    final obj = jsonDecode(utf8.decode(base64.decode(base64.normalize(payload))));
    if (obj is! Map) throw const FormatException('Invalid VMess payload.');
    final m = Map<String, dynamic>.from(obj);
    final host = m['add']?.toString() ?? '';
    final port = int.tryParse(m['port']?.toString() ?? '');
    final id = m['id']?.toString() ?? '';
    if (host.isEmpty || port == null || id.isEmpty) throw const FormatException('Incomplete VMess profile.');
    final q = <String, String>{
      'type': m['net']?.toString() ?? 'raw',
      'security': (m['tls']?.toString() ?? '').isEmpty ? 'none' : m['tls'].toString(),
      if ((m['sni']?.toString() ?? '').isNotEmpty) 'sni': m['sni'].toString(),
      if ((m['host']?.toString() ?? '').isNotEmpty) 'host': m['host'].toString(),
      if ((m['path']?.toString() ?? '').isNotEmpty) 'path': m['path'].toString(),
      if ((m['fp']?.toString() ?? '').isNotEmpty) 'fp': m['fp'].toString(),
    };
    final u = Uri(scheme: 'vmess', host: host, port: port, queryParameters: q);
    return {
      'tag': 'proxy',
      'protocol': 'vmess',
      'settings': {'address': host, 'port': port, 'id': id, 'security': (m['scy']?.toString() ?? '').isEmpty ? 'auto' : m['scy'].toString(), 'level': 0},
      'streamSettings': _stream(u, q['security']!),
    };
  }

  Map<String, dynamic> _stream(Uri u, String security) {
    final q = u.queryParameters;
    var method = (q['type'] ?? q['method'] ?? 'raw').toLowerCase();
    if (method == 'tcp' || method == 'none') method = 'raw';
    if (method == 'ws') method = 'websocket';
    final s = <String, dynamic>{'method': method, 'security': security};
    if (method == 'raw') {
      s['rawSettings'] = {'header': {'type': 'none'}};
    } else if (method == 'websocket') {
      s['wsSettings'] = {if ((q['path'] ?? '').isNotEmpty) 'path': q['path'], if ((q['host'] ?? '').isNotEmpty) 'headers': {'Host': q['host']}};
    } else if (method == 'grpc') {
      s['grpcSettings'] = {if ((q['serviceName'] ?? q['path'] ?? '').isNotEmpty) 'serviceName': q['serviceName'] ?? q['path']};
    } else if (method == 'xhttp') {
      s['xhttpSettings'] = {if ((q['path'] ?? '').isNotEmpty) 'path': q['path'], if ((q['host'] ?? '').isNotEmpty) 'host': q['host']};
    } else {
      throw FormatException('Transport $method is not generated yet.');
    }
    if (security == 'reality') {
      final key = q['pbk'] ?? q['publicKey'] ?? q['password'] ?? '';
      final sni = q['sni'] ?? q['serverName'] ?? '';
      if (key.isEmpty || sni.isEmpty) throw const FormatException('REALITY requires SNI and public key.');
      s['realitySettings'] = {'serverName': sni, 'fingerprint': q['fp'] ?? 'chrome', 'password': key, 'shortId': q['sid'] ?? q['shortId'] ?? '', 'spiderX': q['spx'] ?? q['spiderX'] ?? ''};
    } else if (security == 'tls') {
      s['tlsSettings'] = {'serverName': q['sni'] ?? q['serverName'] ?? u.host, 'allowInsecure': q['allowInsecure'] == '1' || q['allowInsecure'] == 'true', if ((q['fp'] ?? '').isNotEmpty) 'fingerprint': q['fp']};
    } else if (security != 'none') {
      throw FormatException('Security $security is not generated yet.');
    }
    return s;
  }
}
