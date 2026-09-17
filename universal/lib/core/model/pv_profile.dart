import 'dart:convert';

/// Canonical profile schema version written by [PVProfile.toJson].
///
/// v2 adds transport/security/dnsPolicy/routingPolicy/engineRequirements and
/// secretRefs. Reading is tolerant: v1 documents simply leave the new fields
/// empty and keep loading unchanged.
const int pvProfileSchemaVersion = 2;

class PVProfile {
  const PVProfile({
    required this.id,
    required this.name,
    required this.protocol,
    required this.sourceType,
    required this.rawSource,
    required this.createdAt,
    this.endpoint,
    this.favorite = false,
    this.lastUsedAt,
    this.subscriptionUrl,
    this.unsupportedFields = const <String>[],
    this.metadata = const <String, String>{},
    this.transport,
    this.security,
    this.dnsPolicy,
    this.routingPolicy,
    this.engineRequirements = const <String, String>{},
    this.secretRefs = const <String, String>{},
  });

  final String id;
  final String name;
  final String protocol;
  final String sourceType;
  final String rawSource;
  final DateTime createdAt;
  final String? endpoint;
  final bool favorite;
  final DateTime? lastUsedAt;
  final String? subscriptionUrl;
  final List<String> unsupportedFields;
  final Map<String, String> metadata;

  /// Wire transport of the primary hop: raw/tcp, websocket, grpc, xhttp,
  /// httpupgrade, splithttp, quic, kcp... `null` means the profile did not
  /// declare one and the adapter applies its protocol default.
  final String? transport;

  /// Wire security of the primary hop: none, tls, reality.
  final String? security;

  /// DNS strategy requested by the profile: system, secure, cloudflare, off.
  /// `null` lets the selected adapter apply its own default policy.
  final String? dnsPolicy;

  /// Routing strategy: proxyAll, bypassIR (Iranian ranges go direct),
  /// `null` = adapter default (private LAN always direct, everything proxied).
  final String? routingPolicy;

  /// What the profile needs from an engine, e.g.:
  /// `{'engine': 'xray', 'protocols': 'vless,vmess'}`.
  /// Adapters that do not satisfy the requirements must refuse the profile.
  final Map<String, String> engineRequirements;

  /// Indirection for out-of-band secrets: field name -> SecretStore ref.
  /// Placeholders in `rawSource` are resolved by the adapter at config time,
  /// so secret material never needs to live inside the profile document.
  final Map<String, String> secretRefs;

  PVProfile copyWith({
    String? name,
    String? rawSource,
    bool? favorite,
    DateTime? lastUsedAt,
    String? endpoint,
    String? subscriptionUrl,
    List<String>? unsupportedFields,
    Map<String, String>? metadata,
    String? transport,
    String? security,
    String? dnsPolicy,
    String? routingPolicy,
    Map<String, String>? engineRequirements,
    Map<String, String>? secretRefs,
  }) {
    return PVProfile(
      id: id,
      name: name ?? this.name,
      rawSource: rawSource ?? this.rawSource,
      protocol: protocol,
      sourceType: sourceType,
      createdAt: createdAt,
      endpoint: endpoint ?? this.endpoint,
      favorite: favorite ?? this.favorite,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
      unsupportedFields: unsupportedFields ?? this.unsupportedFields,
      metadata: metadata ?? this.metadata,
      transport: transport ?? this.transport,
      security: security ?? this.security,
      dnsPolicy: dnsPolicy ?? this.dnsPolicy,
      routingPolicy: routingPolicy ?? this.routingPolicy,
      engineRequirements: engineRequirements ?? this.engineRequirements,
      secretRefs: secretRefs ?? this.secretRefs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': pvProfileSchemaVersion,
        'id': id,
        'name': name,
        'protocol': protocol,
        'sourceType': sourceType,
        'rawSource': rawSource,
        'createdAt': createdAt.toIso8601String(),
        'endpoint': endpoint,
        'favorite': favorite,
        'lastUsedAt': lastUsedAt?.toIso8601String(),
        'subscriptionUrl': subscriptionUrl,
        'unsupportedFields': unsupportedFields,
        'metadata': metadata,
        'transport': transport,
        'security': security,
        'dnsPolicy': dnsPolicy,
        'routingPolicy': routingPolicy,
        'engineRequirements': engineRequirements,
        'secretRefs': secretRefs,
      };

  factory PVProfile.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['metadata'];
    Map<String, String> stringMap(dynamic raw) => raw is Map
        ? raw.map((dynamic key, dynamic value) => MapEntry(key.toString(), value.toString()))
        : const <String, String>{};
    return PVProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Imported profile',
      protocol: json['protocol'] as String? ?? 'Unknown',
      sourceType: json['sourceType'] as String? ?? 'unknown',
      rawSource: json['rawSource'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      endpoint: json['endpoint'] as String?,
      favorite: json['favorite'] as bool? ?? false,
      lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? ''),
      subscriptionUrl: json['subscriptionUrl'] as String?,
      unsupportedFields: (json['unsupportedFields'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(growable: false),
      metadata: stringMap(rawMeta),
      transport: json['transport'] as String?,
      security: json['security'] as String?,
      dnsPolicy: json['dnsPolicy'] as String?,
      routingPolicy: json['routingPolicy'] as String?,
      engineRequirements: stringMap(json['engineRequirements']),
      secretRefs: stringMap(json['secretRefs']),
    );
  }

  static String encodeList(List<PVProfile> profiles) =>
      jsonEncode(profiles.map((PVProfile profile) => profile.toJson()).toList(growable: false));

  static List<PVProfile> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <PVProfile>[];
    return decoded
        .whereType<Map>()
        .map((Map item) => PVProfile.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
