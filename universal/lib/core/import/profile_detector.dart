import 'dart:convert';

import '../model/pv_profile.dart';

class ProfileDetectionResult {
  const ProfileDetectionResult({
    required this.protocol,
    required this.name,
    required this.sourceType,
    required this.rawSource,
    this.endpoint,
    this.subscriptionUrl,
    this.metadata = const <String, String>{},
    this.unsupportedFields = const <String>[],
  });

  final String protocol;
  final String name;
  final String sourceType;
  final String rawSource;
  final String? endpoint;
  final String? subscriptionUrl;
  final Map<String, String> metadata;
  final List<String> unsupportedFields;

  PVProfile toProfile() => PVProfile(
        id: '${DateTime.now().microsecondsSinceEpoch}-${protocol.toLowerCase()}',
        name: name,
        protocol: protocol,
        sourceType: sourceType,
        rawSource: rawSource,
        createdAt: DateTime.now(),
        endpoint: endpoint,
        subscriptionUrl: subscriptionUrl,
        metadata: metadata,
        unsupportedFields: unsupportedFields,
      );
}

class ProfileDetector {
  static const Set<String> supportedSchemes = <String>{
    'vless',
    'vmess',
    'trojan',
    'ss',
    'hysteria',
    'hysteria2',
    'hy2',
    'tuic',
    'socks',
    'socks5',
    'http',
    'https',
    'wireguard',
  };

  ProfileDetectionResult detect(String input, {String sourceType = 'text'}) {
    final raw = input.trim();
    if (raw.isEmpty) throw const FormatException('Configuration is empty.');

    if (_looksLikeWireGuard(raw)) return _wireGuard(raw, sourceType);
    if (_looksLikeOpenVpn(raw)) return _openVpn(raw, sourceType);
    if (_looksLikeJson(raw)) return _json(raw, sourceType);
    if (_looksLikeClashYaml(raw)) return _clash(raw, sourceType);

    final firstLine = raw.split(RegExp(r'\s+')).first;
    final uri = Uri.tryParse(firstLine);
    if (uri != null && supportedSchemes.contains(uri.scheme.toLowerCase())) {
      if (uri.scheme.toLowerCase() == 'vmess') return _vmess(firstLine, sourceType);
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return ProfileDetectionResult(
          protocol: 'Subscription / HTTP',
          name: uri.host.isEmpty ? 'Subscription' : uri.host,
          sourceType: 'subscription',
          rawSource: raw,
          endpoint: uri.host,
          subscriptionUrl: firstLine,
        );
      }
      return _uri(firstLine, sourceType);
    }

    final lines = raw.split(RegExp(r'[\r\n]+')).where((String line) => line.trim().isNotEmpty).toList();
    if (lines.length > 1 && lines.any((String line) {
      final parsed = Uri.tryParse(line.trim());
      return parsed != null && supportedSchemes.contains(parsed.scheme.toLowerCase());
    })) {
      return ProfileDetectionResult(
        protocol: 'Subscription bundle',
        name: 'Imported bundle',
        sourceType: 'bundle',
        rawSource: raw,
        metadata: <String, String>{'entries': lines.length.toString()},
      );
    }

    throw const FormatException('PVNetwork could not identify this configuration format.');
  }

  bool _looksLikeOpenVpn(String raw) {
    final l = raw.toLowerCase();
    return (l.contains('\nclient') || l.startsWith('client\n') || l.startsWith('client\r')) &&
        (l.contains('\nremote ') || l.contains('\nproto ') || l.contains('<ca>'));
  }

  bool _looksLikeWireGuard(String raw) {
    final l = raw.toLowerCase();
    return l.contains('[interface]') && l.contains('[peer]') &&
        (l.contains('privatekey') || l.contains('publickey'));
  }

  bool _looksLikeJson(String raw) => raw.startsWith('{') && raw.endsWith('}');

  bool _looksLikeClashYaml(String raw) {
    final l = raw.toLowerCase();
    return l.contains('proxies:') || l.contains('proxy-groups:') || l.contains('rule-providers:');
  }

  ProfileDetectionResult _openVpn(String raw, String sourceType) {
    final remote = RegExp(r'^\s*remote\s+([^\s]+)(?:\s+(\d+))?', multiLine: true).firstMatch(raw);
    final proto = RegExp(r'^\s*proto\s+([^\s]+)', multiLine: true).firstMatch(raw);
    final host = remote?.group(1);
    final port = remote?.group(2);
    return ProfileDetectionResult(
      protocol: 'OpenVPN ${proto?.group(1)?.toUpperCase() ?? ''}'.trim(),
      name: host == null ? 'OpenVPN profile' : 'OpenVPN · $host',
      sourceType: sourceType,
      rawSource: raw,
      endpoint: host == null ? null : (port == null ? host : '$host:$port'),
    );
  }

  ProfileDetectionResult _wireGuard(String raw, String sourceType) {
    final endpoint = RegExp(r'^\s*Endpoint\s*=\s*([^\r\n]+)', multiLine: true, caseSensitive: false)
        .firstMatch(raw)
        ?.group(1)
        ?.trim();
    return ProfileDetectionResult(
      protocol: 'WireGuard',
      name: endpoint == null ? 'WireGuard profile' : 'WireGuard · $endpoint',
      sourceType: sourceType,
      rawSource: raw,
      endpoint: endpoint,
    );
  }

  ProfileDetectionResult _json(String raw, String sourceType) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('JSON root must be an object.');
    final data = Map<String, dynamic>.from(decoded);
    if (data.containsKey('outbounds') || data.containsKey('route') || data.containsKey('dns')) {
      return ProfileDetectionResult(
        protocol: 'sing-box / Xray JSON',
        name: 'JSON profile',
        sourceType: sourceType,
        rawSource: raw,
        unsupportedFields: const <String>['Full semantic validation requires the selected core adapter.'],
      );
    }
    throw const FormatException('JSON is valid but does not look like a supported network profile.');
  }

  ProfileDetectionResult _clash(String raw, String sourceType) => ProfileDetectionResult(
        protocol: 'Clash / Mihomo YAML',
        name: 'Clash / Mihomo profile',
        sourceType: sourceType,
        rawSource: raw,
        unsupportedFields: const <String>['YAML normalization will be finalized with the Mihomo adapter.'],
      );

  ProfileDetectionResult _vmess(String raw, String sourceType) {
    final payload = raw.substring('vmess://'.length);
    try {
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final obj = jsonDecode(decoded);
      if (obj is Map) {
        final map = Map<String, dynamic>.from(obj);
        final host = map['add']?.toString();
        final port = map['port']?.toString();
        final ps = map['ps']?.toString();
        return ProfileDetectionResult(
          protocol: 'VMess',
          name: (ps != null && ps.trim().isNotEmpty) ? ps.trim() : (host ?? 'VMess profile'),
          sourceType: sourceType,
          rawSource: raw,
          endpoint: host == null ? null : (port == null ? host : '$host:$port'),
        );
      }
    } catch (_) {
      // Keep the original payload; adapter-level validation will provide exact diagnostics.
    }
    return ProfileDetectionResult(
      protocol: 'VMess',
      name: 'VMess profile',
      sourceType: sourceType,
      rawSource: raw,
      unsupportedFields: const <String>['VMess payload requires adapter-level validation.'],
    );
  }

  ProfileDetectionResult _uri(String raw, String sourceType) {
    final uri = Uri.parse(raw);
    final scheme = uri.scheme.toLowerCase();
    final protocol = switch (scheme) {
      'vless' => 'VLESS',
      'trojan' => 'Trojan',
      'ss' => 'Shadowsocks',
      'hysteria' => 'Hysteria',
      'hysteria2' || 'hy2' => 'Hysteria2',
      'tuic' => 'TUIC',
      'wireguard' => 'WireGuard',
      'socks' || 'socks5' => 'SOCKS5',
      _ => scheme.toUpperCase(),
    };
    final label = Uri.decodeComponent(uri.fragment).trim();
    final endpoint = uri.host.isEmpty ? null : '${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    final security = uri.queryParameters['security'];
    final flow = uri.queryParameters['flow'];
    final displayProtocol = protocol == 'VLESS' && security == 'reality' ? 'VLESS · REALITY' : protocol;
    return ProfileDetectionResult(
      protocol: displayProtocol,
      name: label.isNotEmpty ? label : (endpoint ?? '$protocol profile'),
      sourceType: sourceType,
      rawSource: raw,
      endpoint: endpoint,
      metadata: <String, String>{
        if (security != null) 'security': security,
        if (flow != null) 'flow': flow,
      },
    );
  }
}
