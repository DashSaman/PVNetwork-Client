import 'dart:convert';

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

  PVProfile copyWith({
    String? name,
    bool? favorite,
    DateTime? lastUsedAt,
  }) {
    return PVProfile(
      id: id,
      name: name ?? this.name,
      protocol: protocol,
      sourceType: sourceType,
      rawSource: rawSource,
      createdAt: createdAt,
      endpoint: endpoint,
      favorite: favorite ?? this.favorite,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      subscriptionUrl: subscriptionUrl,
      unsupportedFields: unsupportedFields,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 1,
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
      };

  factory PVProfile.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['metadata'];
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
      metadata: rawMeta is Map
          ? rawMeta.map((dynamic key, dynamic value) => MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
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
