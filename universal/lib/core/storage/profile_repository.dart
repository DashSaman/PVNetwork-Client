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

  Future<List<PVProfile>> loadProfiles() async {
    final raw = await _storage.read(key: _profilesKey);
    if (raw == null || raw.isEmpty) return <PVProfile>[];
    late final List<PVProfile> decoded;
    try {
      decoded = PVProfile.decodeList(raw);
    } catch (_) {
      // Never overwrite a corrupted original during recovery.
      return <PVProfile>[];
    }
    final migrated = await protectLegacyProfiles(decoded);
    if (List<int>.generate(decoded.length, (i) => i)
        .any((i) => !identical(migrated[i], decoded[i]))) {
      // Persist only after EVERY sensitive field was moved to SecretStore.
      await saveProfiles(migrated);
    }
    return migrated;
  }

  /// Idempotent data migration for v0.3 records that previously serialized
  /// raw credentials. Runs before the list is used by UI or future exports.
  Future<List<PVProfile>> protectLegacyProfiles(List<PVProfile> profiles) async {
    final migrated = <PVProfile>[];
    for (final profile in profiles) {
      migrated.add(await secureImportedProfile(profile));
    }
    return migrated;
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

  /// Keeps imported configuration material out of the serialized profile.
  /// The URI may contain UUIDs/passwords; subscription URLs can contain
  /// bearer tokens. These must not be included in JSON backups/logs.
  Future<PVProfile> secureImportedProfile(PVProfile profile) async {
    final refs = Map<String, String>.of(profile.secretRefs);
    var raw = profile.rawSource;
    var subscription = profile.subscriptionUrl;
    var changed = false;
    if (raw.isNotEmpty &&
        !(raw == r'$ref{rawSource}' && refs.containsKey('rawSource'))) {
      refs['rawSource'] = await writeProfileSecret(profile, 'rawSource', raw);
      raw = r'$ref{rawSource}';
      changed = true;
    }
    if (subscription != null &&
        subscription.isNotEmpty &&
        !(subscription == r'$ref{subscriptionUrl}' &&
            refs.containsKey('subscriptionUrl'))) {
      refs['subscriptionUrl'] =
          await writeProfileSecret(profile, 'subscriptionUrl', subscription);
      subscription = r'$ref{subscriptionUrl}';
      changed = true;
    }
    if (!changed) return profile;
    return profile.copyWith(
      rawSource: raw,
      subscriptionUrl: subscription,
      secretRefs: refs,
    );
  }

  /// Deletes every secret attached to [profile] (call on profile removal).
  Future<void> deleteProfileSecrets(PVProfile profile) async {
    // Delete references explicitly so backends that cannot enumerate keys
    // still remove credentials. Also sweep the legacy per-profile namespace.
    for (final ref in profile.secretRefs.values.toSet()) {
      await secrets.delete(ref);
    }
    await secrets.deletePrefix('${profile.id}.');
  }

  /// Resolves the full secret view of [profile]: out-of-band refs replace
  /// placeholders, e.g. rawSource contains `$ref{password}` markers which are
  /// substituted with values from [SecretStore].
  Future<PVProfile> resolveSecrets(PVProfile profile) async {
    if (profile.secretRefs.isEmpty) return profile;
    var raw = profile.rawSource;
    var subscription = profile.subscriptionUrl;
    for (final field in profile.secretRefs.keys) {
      final value = await readProfileSecret(profile, field);
      if (value == null) continue;
      raw = raw.replaceAll('\$ref{$field}', value);
      subscription = subscription?.replaceAll('\$ref{$field}', value);
    }
    return profile.copyWith(rawSource: raw, subscriptionUrl: subscription);
  }
}
