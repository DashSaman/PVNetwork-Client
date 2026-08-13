import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/pv_profile.dart';

class ProfileRepository {
  ProfileRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _profilesKey = 'pvnetwork.profiles.v1';
  static const _selectedKey = 'pvnetwork.selected.v1';
  static const _languageKey = 'pvnetwork.language.v1';
  static const _themeKey = 'pvnetwork.theme.v1';

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
}
