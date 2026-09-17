import 'dart:convert';

import '../model/pv_profile.dart';

/// Builds Xray-core client configurations from [PVProfile] documents.
///
/// Supported outbound protocols: VLESS, VMess, Trojan, Shadowsocks, SOCKS,
/// HTTP. Hysteria/Hysteria2/TUIC/WireGuard profiles must be refused by the
/// adapter layer (see `XrayAdapter.capabilities`), never silently mis-routed.
class XrayConfigBuilder {
  const XrayConfigBuilder();

  static const healthPort = 19670;

  /// Protocols this builder can generate real configs for.
  static const Set<String> supportedProtocols = <String>{
    'vless',
    'vmess',
    'trojan',
    'shadowsocks',
    'ss',
    'socks',
    'socks5',
    'http',
    'https',
  };

  /// Private ranges that always stay direct so LAN/localhost keep working
  /// while the tunnel is up. Explicit CIDR literals avoid a hard dependency
  /// on geoip.dat for the default policy.
  static const List<String> privateCidrs = <String>[
    '0.0.0.0/8',
    '10.0.0.0/8',
    '100.64.0.0/10',
    '127.0.0.0/8',
    '169.254.0.0/16',
    '172.16.0.0/12',
    '192.168.0.0/16',
    '224.0.0.0/4',
    '240.0.0.0/4',
    '::1/128',
    'fe80::/10',
    'fc00::/7',
  ];

  String build(PVProfile p) => const JsonEncoder.withIndent('  ').convert(buildMap(p));

  Map<String, dynamic> buildMap(PVProfile p) {
    final dnsPolicy = _normalizeDnsPolicy(p.dnsPolicy);
    final dnsOn = dnsPolicy != 'off';
    final cfg = <String, dynamic>{
      'log': {'loglevel': 'warning'},
      if (dnsOn) 'dns': _dnsBlock(dnsPolicy),
      'stats': <String, dynamic>{},
      'policy': {
        'levels': {
          '0': {'statsUserUplink': true, 'statsUserDownlink': true},
        },
        'system': {'statsOutboundUplink': true, 'statsOutboundDownlink': true},
      },
      'inbounds': [
        {
          'tag': 'tun-in',
          'protocol': 'tun',
          'settings': {'mtu': 1500, 'userLevel': 0},
          'sniffing': {'enabled': true, 'destOverride': ['http', 'tls']},
        },
        {'tag': 'health-in', 'listen': '127.0.0.1', 'port': healthPort, 'protocol': 'http', 'settings': {}},
      ],
      'outbounds': [
        _outbound(p),
        {'tag': 'direct', 'protocol': 'freedom', 'settings': {}},
        {'tag': 'block', 'protocol': 'blackhole', 'settings': {}},
        if (dnsOn)
          {
            'tag': 'dns-out',
            'protocol': 'dns',
            'settings': {'address': dnsPolicy == 'cloudflare' ? '1.1.1.1' : '8.8.8.8'},
            'proxySettings': {'tag': 'proxy'},
          },
      ],
      'routing': _routingBlock(p.routingPolicy, dnsOn),
    };
    return cfg;
  }

  Map<String, dynamic> _outbound(PVProfile p) {
    final raw = p.rawSource.trim();
    if (raw.startsWith('vless://')) return _vless(Uri.parse(raw));
    if (raw.startsWith('trojan://')) return _trojan(Uri.parse(raw));
    if (raw.startsWith('vmess://')) return _vmess(raw);
    if (raw.startsWith('ss://')) return _shadowsocks(raw);
    if (raw.startsWith('socks://') || raw.startsWith('socks5://')) return _socks(Uri.parse(raw));
    if (raw.startsWith('http://') || raw.startsWith('https://')) return _httpOutbound(Uri.parse(raw));
    final engine = p.engineRequirements['engine'] ?? p.protocol;
    throw FormatException(
        'Xray cannot serve ${p.protocol} (engine: $engine). This profile needs a different core adapter.');
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

  /// Shadowsocks client outbound. Accepts SIP002 (`ss://b64(method:key)@host:port#tag`,
  /// plain `method:key@host`, plugin query) and the legacy fully-base64 form.
  Map<String, dynamic> _shadowsocks(String raw) {
    var body = raw.substring('ss://'.length);
    if (body.contains('#')) {
      body = body.substring(0, body.indexOf('#'));
    }
    var query = <String, String>{};
    if (body.contains('?')) {
      query = Uri.splitQueryString(body.substring(body.indexOf('?') + 1));
      body = body.substring(0, body.indexOf('?'));
    }
    if ((query['plugin'] ?? '').trim().isNotEmpty) {
      throw const FormatException('Shadowsocks plugins (obfs/v2ray-plugin) are not supported yet.');
    }

    var userinfo = '';
    var hostPort = body;
    if (body.contains('@')) {
      final at = body.lastIndexOf('@');
      userinfo = body.substring(0, at);
      hostPort = body.substring(at + 1);
    }

    String method;
    String password;
    if (userinfo.isNotEmpty) {
      final decoded = userinfo.contains(':')
          ? Uri.decodeComponent(userinfo)
          : utf8.decode(base64.decode(base64.normalize(userinfo)));
      final split = decoded.indexOf(':');
      if (split <= 0 || split == decoded.length - 1) {
        throw const FormatException('Invalid Shadowsocks credentials.');
      }
      method = decoded.substring(0, split);
      password = decoded.substring(split + 1);
    } else {
      // Legacy: whole payload is base64 of "method:password@host:port".
      final decoded = utf8.decode(base64.decode(base64.normalize(hostPort)));
      final at = decoded.lastIndexOf('@');
      if (at <= 0) throw const FormatException('Invalid Shadowsocks URI.');
      final cred = decoded.substring(0, at);
      hostPort = decoded.substring(at + 1);
      final split = cred.indexOf(':');
      if (split <= 0) throw const FormatException('Invalid Shadowsocks credentials.');
      method = cred.substring(0, split);
      password = cred.substring(split + 1);
    }

    final host = _hostOf(hostPort);
    final port = _portOf(hostPort);
    if (method.isEmpty || password.isEmpty || host.isEmpty || port == null) {
      throw const FormatException('Incomplete Shadowsocks profile.');
    }
    return {
      'tag': 'proxy',
      'protocol': 'shadowsocks',
      'settings': {'address': host, 'port': port, 'method': method, 'password': password, 'level': 0},
      'streamSettings': {'method': 'raw', 'security': 'none'},
    };
  }

  Map<String, dynamic> _socks(Uri u) {
    if (u.host.isEmpty || !u.hasPort) throw const FormatException('Incomplete SOCKS profile.');
    final user = Uri.decodeComponent(u.userInfo.split(':').first);
    final pass = u.userInfo.contains(':') ? Uri.decodeComponent(u.userInfo.split(':').last) : '';
    return {
      'tag': 'proxy',
      'protocol': 'socks',
      'settings': {
        'servers': [
          {
            'address': u.host,
            'port': u.port,
            if (user.isNotEmpty)
              'users': [
                {'user': user, 'pass': pass, 'level': 0},
              ],
          },
        ],
      },
      'streamSettings': {'method': 'raw', 'security': 'none'},
    };
  }

  Map<String, dynamic> _httpOutbound(Uri u) {
    if (u.host.isEmpty || !u.hasPort) throw const FormatException('Incomplete HTTP proxy profile.');
    final user = Uri.decodeComponent(u.userInfo.split(':').first);
    final pass = u.userInfo.contains(':') ? Uri.decodeComponent(u.userInfo.split(':').last) : '';
    return {
      'tag': 'proxy',
      'protocol': 'http',
      'settings': {
        'servers': [
          {
            'address': u.host,
            'port': u.port,
            if (user.isNotEmpty)
              'users': [
                {'user': user, 'pass': pass, 'level': 0},
              ],
          },
        ],
      },
      'streamSettings': {'method': 'raw', 'security': u.scheme == 'https' ? 'tls' : 'none'},
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
    } else if (method == 'xhttp' || method == 'splithttp') {
      s['xhttpSettings'] = {if ((q['path'] ?? '').isNotEmpty) 'path': q['path'], if ((q['host'] ?? '').isNotEmpty) 'host': q['host'], 'mode': (q['mode'] ?? 'auto')};
    } else if (method == 'httpupgrade') {
      s['httpupgradeSettings'] = {if ((q['path'] ?? '').isNotEmpty) 'path': q['path'], if ((q['host'] ?? '').isNotEmpty) 'host': q['host']};
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

  /// DNS strategy. `null` maps to `secure` (IP-hosted DoH, no bootstrap
  /// dependency); `off` removes the DNS block entirely.
  Map<String, dynamic> _dnsBlock(String policy) => switch (policy) {
        'system' => {'servers': ['localhost'], 'queryStrategy': 'UseIPv4'},
        'cloudflare' => {
            'servers': ['https://cloudflare-dns.com/dns-query', '1.1.1.1', '1.0.0.1'],
            'queryStrategy': 'UseIPv4',
          },
        _ => {'servers': ['https://8.8.8.8/dns-query', 'https://1.1.1.1/dns-query', '8.8.8.8'], 'queryStrategy': 'UseIPv4'},
      };

  Map<String, dynamic> _routingBlock(String? routingPolicy, bool dnsOn) {
    final rules = <Map<String, dynamic>>[
      {'type': 'field', 'inboundTag': ['health-in'], 'outboundTag': 'proxy'},
      if (dnsOn)
        {'type': 'field', 'port': 53, 'inboundTag': ['tun-in'], 'outboundTag': 'dns-out'},
      {'type': 'field', 'ip': privateCidrs, 'outboundTag': 'direct'},
    ];
    if (routingPolicy == 'bypassIR') {
      // Requires geoip.dat shipped next to the core (InitEnvironment asset
      // location). Missing assets surface as a start error, not silent leaks.
      rules.add({'type': 'field', 'ip': ['geoip:ir'], 'outboundTag': 'direct'});
    }
    return {'domainStrategy': 'AsIs', 'rules': rules};
  }

  String _normalizeDnsPolicy(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'default') return 'secure';
    return switch (raw.toLowerCase()) {
      'system' => 'system',
      'cloudflare' => 'cloudflare',
      'off' || 'disabled' => 'off',
      _ => 'secure',
    };
  }

  static String _hostOf(String hostPort) {
    if (hostPort.startsWith('[')) {
      final end = hostPort.indexOf(']');
      return end > 0 ? hostPort.substring(1, end) : '';
    }
    final colon = hostPort.lastIndexOf(':');
    return colon > 0 ? hostPort.substring(0, colon) : hostPort;
  }

  static int? _portOf(String hostPort) {
    if (hostPort.startsWith('[')) {
      final end = hostPort.indexOf(']');
      if (end < 0 || end + 2 > hostPort.length) return null;
      return int.tryParse(hostPort.substring(end + 2));
    }
    final colon = hostPort.lastIndexOf(':');
    if (colon < 0) return null;
    return int.tryParse(hostPort.substring(colon + 1));
  }
}
