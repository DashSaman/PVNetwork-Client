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
