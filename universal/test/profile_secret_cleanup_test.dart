import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/core/model/pv_profile.dart';
import 'package:vpn/core/storage/profile_repository.dart';
import 'package:vpn/core/storage/secret_store.dart';

void main() {
  test('deleting one profile clears explicit refs and legacy scoped values', () async {
    final secrets = InMemorySecretStore();
    final repo = ProfileRepository(secretStore: secrets);
    await secrets.write('custom-ref-1', 'secret-a');
    await secrets.write('profile-1.legacyPassword', 'secret-b');
    await secrets.write('profile-2.password', 'secret-c');

    final profile = PVProfile(
      id: 'profile-1',
      name: 'One',
      protocol: 'VLESS',
      sourceType: 'manual',
      rawSource: 'vless://example',
      createdAt: DateTime.utc(2026, 10, 27),
      secretRefs: const {'password': 'custom-ref-1'},
    );
    await repo.deleteProfileSecrets(profile);

    expect(await secrets.read('custom-ref-1'), isNull);
    expect(await secrets.read('profile-1.legacyPassword'), isNull);
    expect(await secrets.read('profile-2.password'), 'secret-c');
  });

  test('import secrets are never serialized in cleartext profile JSON', () async {
    final secrets = InMemorySecretStore();
    final repo = ProfileRepository(secretStore: secrets);
    final original = PVProfile(
      id: 'imported-1',
      name: 'Imported',
      protocol: 'Subscription / HTTP',
      sourceType: 'subscription',
      rawSource: 'https://sub.example.com/secret-token',
      subscriptionUrl: 'https://sub.example.com/secret-token',
      createdAt: DateTime.utc(2026, 10, 27),
    );
    final protected = await repo.secureImportedProfile(original);
    expect(PVProfile.encodeList([protected]), isNot(contains('secret-token')));
    expect(protected.rawSource, r'$ref{rawSource}');
    expect(protected.subscriptionUrl, r'$ref{subscriptionUrl}');
    final resolved = await repo.resolveSecrets(protected);
    expect(resolved.rawSource, original.rawSource);
    expect(resolved.subscriptionUrl, original.subscriptionUrl);
    await repo.deleteProfileSecrets(protected);
    expect(await secrets.read('imported-1.rawSource'), isNull);
    expect(await secrets.read('imported-1.subscriptionUrl'), isNull);
  });

  test('legacy profile migration is idempotent and preserves user data', () async {
    final secrets = InMemorySecretStore();
    final repo = ProfileRepository(secretStore: secrets);
    final legacy = PVProfile(
      id: 'old',
      name: 'Legacy server',
      protocol: 'VLESS',
      sourceType: 'clipboard',
      rawSource: 'vless://sensitive-uuid@vpn.example.com:443',
      createdAt: DateTime.utc(2026, 9, 1),
      subscriptionUrl: 'https://sub.example.com/access-token',
    );
    final once = await repo.protectLegacyProfiles([legacy]);
    expect(PVProfile.encodeList(once), isNot(contains('sensitive-uuid')));
    expect(PVProfile.encodeList(once), isNot(contains('access-token')));
    expect(once.first.name, legacy.name);
    expect(once.first.id, legacy.id);
    final twice = await repo.protectLegacyProfiles(once);
    expect(identical(twice.first, once.first), isTrue);
    final resolved = await repo.resolveSecrets(twice.first);
    expect(resolved.rawSource, legacy.rawSource);
    expect(resolved.subscriptionUrl, legacy.subscriptionUrl);
  });

  test('resolves field placeholders without overwriting stored source', () async {
    final secrets = InMemorySecretStore();
    final repo = ProfileRepository(secretStore: secrets);
    await secrets.write('p.password', 'safesecret');
    final profile = PVProfile(
      id: 'p',
      name: 'Proxy',
      protocol: 'Trojan',
      sourceType: 'manual',
      rawSource: 'trojan://\$ref{password}@vpn.example.com:443',
      createdAt: DateTime.utc(2026, 10, 27),
      secretRefs: const {'password': 'p.password'},
    );
    final resolved = await repo.resolveSecrets(profile);
    expect(resolved.rawSource, 'trojan://safesecret@vpn.example.com:443');
    expect(profile.rawSource, 'trojan://\$ref{password}@vpn.example.com:443');
  });
}
