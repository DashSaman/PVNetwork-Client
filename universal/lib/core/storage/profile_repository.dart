import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/pv_profile.dart';
import 'secret_store.dart';

class ProfileRepository {
  ProfileRepository({FlutterSecureStorage? storage, SecretStore? secretStore})
      : _storage = storage ?? const FlutterSecureStorage(),
        secrets = secretStore ?? SecureStorageSecretStore(storage: storage);

  final FlutterSecureStorage _storage;

  /// Secret indirection layer. Profiles never embed out-of-band secret
  /// material; they point at refs resolved through this store.
  final SecretStore secrets;

  static const _profilesKey = 'pvnetwork.profiles.v1';
  static const _selectedKey = 'pvnetwork.selected.v1';
  static const _languageKey = 'pvnetwork.language.v1';
  static const _themeKey = 'pvnetwork.theme.v1';
  static const _secretPrefix = 'pvnetwork.secret.';

  Future<List<PVProfile>> loadProfiles() async {
    final raw = await _storage.read(key: _profilesKey);
    if (raw == null || raw.isEmpty) return <PVProfile>[];
    try {
      return PVProfile.decodeList(raw);
    } catch (_) {
      return <PVProfile>[];
    }
  }

  Future<void> saveProfiles(List<PVProfile> profiles) =>
      _storage.write(key: _profilesKey, value: PVProfile.encodeList(profiles));

  Future<String?> loadSelectedProfileId() => _storage.read(key: _selectedKey);

  Future<void> saveSelectedProfileId(String? id) => id == null
      ? _storage.delete(key: _selectedKey)
      : _storage.write(key: _selectedKey, value: id);

  Future<String?> loadLanguage() => _storage.read(key: _languageKey);
  Future<void> saveLanguage(String value) => _storage.write(key: _languageKey, value: value);
  Future<String?> loadTheme() => _storage.read(key: _themeKey);
  Future<void> saveTheme(String value) => _storage.write(key: _themeKey, value: value);

  /// Stable ref for one secret field of one profile.
  static String secretRef(String profileId, String field) => '$profileId.$field';

  /// Writes [value] for profile [field] and returns the ref to store inside
  /// `PVProfile.secretRefs`.
  Future<String> writeProfileSecret(PVProfile profile, String field, String value) async {
    final ref = secretRef(profile.id, field);
    await secrets.write(ref, value);
    return ref;
  }

  Future<String?> readProfileSecret(PVProfile profile, String field) async {
    final ref = profile.secretRefs[field];
    if (ref == null || ref.isEmpty) return null;
    return secrets.read(ref);
  }

  /// Deletes every secret attached to [profile] (call on profile removal).
  Future<void> deleteProfileSecrets(PVProfile profile) =>
      secrets.deletePrefix('$_secretPrefix${profile.id}.');

  /// Resolves the full secret view of [profile]: out-of-band refs replace
  /// placeholders, e.g. rawSource contains `$ref{password}` markers which are
  /// substituted with values from [SecretStore].
  Future<PVProfile> resolveSecrets(PVProfile profile) async {
    if (profile.secretRefs.isEmpty) return profile;
    var raw = profile.rawSource;
    for (final field in profile.secretRefs.keys) {
      final value = await readProfileSecret(profile, field);
      if (value == null) continue;
      raw = raw.replaceAll('\$ref{$field}', value);
    }
    return raw == profile.rawSource ? profile : profile.copyWith(rawSource: raw);
  }
}
