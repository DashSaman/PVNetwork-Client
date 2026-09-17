import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract key/value storage for secret material.
///
/// Profiles reference secret material indirectly through
/// `PVProfile.secretRefs` (field -> ref). The raw values live here, never
/// inside the profile document itself, so exporting/sharing a profile cannot
/// leak passwords or keys.
abstract interface class SecretStore {
  Future<String?> read(String ref);

  Future<void> write(String ref, String value);

  Future<void> delete(String ref);

  /// Removes every entry whose ref starts with [prefix] (used when a profile
  /// is deleted). Implementations may ignore this when the backend cannot
  /// enumerate keys; callers must then delete explicit refs.
  Future<void> deletePrefix(String prefix);
}

/// Production backend backed by `flutter_secure_storage` (Keychain /
/// Keystore / libsecret depending on platform).
class SecureStorageSecretStore implements SecretStore {
  SecureStorageSecretStore({FlutterSecureStorage? storage, this.prefix = 'pvnetwork.secret.'})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final String prefix;

  String scoped(String ref) => ref.startsWith(prefix) ? ref : '$prefix$ref';

  @override
  Future<String?> read(String ref) => _storage.read(key: scoped(ref));

  @override
  Future<void> write(String ref, String value) => _storage.write(key: scoped(ref), value: value);

  @override
  Future<void> delete(String ref) => _storage.delete(key: scoped(ref));

  @override
  Future<void> deletePrefix(String prefix) async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      final relative = key.startsWith(this.prefix) ? key.substring(this.prefix.length) : null;
      if (relative != null && relative.startsWith(prefix)) {
        await _storage.delete(key: key);
      }
    }
  }
}

/// Volatile backend for tests, previews and dependency-free desktop runs.
class InMemorySecretStore implements SecretStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String ref) async => values[ref];

  @override
  Future<void> write(String ref, String value) async => values[ref] = value;

  @override
  Future<void> delete(String ref) async => values.remove(ref);

  @override
  Future<void> deletePrefix(String prefix) async {
    values.removeWhere((key, _) => key.startsWith(prefix));
  }
}
