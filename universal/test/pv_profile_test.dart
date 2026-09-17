import 'package:flutter_test/flutter_test.dart';
import 'package:vpn/core/model/pv_profile.dart';
import 'package:vpn/core/storage/profile_repository.dart';
import 'package:vpn/core/storage/secret_store.dart';

PVProfile sample() => PVProfile(
      id: 'p1',
      name: 'Berlin',
      protocol: 'VLESS',
      sourceType: 'text',
      rawSource: 'vless://uuid@h:443',
      createdAt: DateTime.utc(2026, 1, 1),
      endpoint: 'h:443',
      transport: 'websocket',
      security: 'tls',
      dnsPolicy: 'secure',
      routingPolicy: 'bypassIR',
      engineRequirements: const {'engine': 'xray', 'protocols': 'vless'},
      secretRefs: const {'password': 'p1.password'},
    );

void main() {
  test('v2 JSON roundtrip keeps all new fields', () {
    final raw = PVProfile.encodeList([sample()]);
    final list = PVProfile.decodeList(raw);
    expect(list, hasLength(1));
    final p = list.single;
    expect(p.transport, 'websocket');
    expect(p.security, 'tls');
    expect(p.dnsPolicy, 'secure');
    expect(p.routingPolicy, 'bypassIR');
    expect(p.engineRequirements['engine'], 'xray');
    expect(p.secretRefs['password'], 'p1.password');
  });

  test('JSON documents are stamped as schema v2', () {
    final json = sample().toJson();
    expect(json['version'], pvProfileSchemaVersion);
  });

  test('v1 documents still load (forward compatibility)', () {
    const v1 = '''
    [{
      "id": "old",
      "name": "Legacy",
      "protocol": "VMess",
      "sourceType": "text",
      "rawSource": "vmess://old",
      "createdAt": "2025-01-01T00:00:00.000Z",
      "endpoint": "h:1",
      "favorite": false,
      "unsupportedFields": [],
      "metadata": {"a": "b"}
    }]
    ''';
    final list = PVProfile.decodeList(v1);
    expect(list, hasLength(1));
    final p = list.single;
    expect(p.id, 'old');
    expect(p.transport, isNull);
    expect(p.security, isNull);
    expect(p.dnsPolicy, isNull);
    expect(p.routingPolicy, isNull);
    expect(p.engineRequirements, isEmpty);
    expect(p.secretRefs, isEmpty);
  });

  test('copyWith overrides rawSource and keeps identity fields', () {
    final p = sample();
    final updated = p.copyWith(rawSource: 'vless://new@h:443', name: 'Frankfurt');
    expect(updated.id, 'p1');
    expect(updated.createdAt, p.createdAt);
    expect(updated.rawSource, 'vless://new@h:443');
    expect(updated.name, 'Frankfurt');
    expect(updated.transport, 'websocket');
  });

  test('resolveSecrets substitutes placeholders from the secret store', () async {
    final store = InMemorySecretStore();
    await store.write('p1.password', 's3cret');
    final profile = sample().copyWith(rawSource: r'trojan://$ref{password}@h:443');
    final repo = ProfileRepository(secretStore: store);
    final resolved = await repo.resolveSecrets(profile);
    expect(resolved.rawSource, 'trojan://s3cret@h:443');
  });

  test('writeProfileSecret returns a stable ref', () async {
    final store = InMemorySecretStore();
    final repo = ProfileRepository(secretStore: store);
    final ref = await repo.writeProfileSecret(sample(), 'password', 'topsecret');
    expect(ref, 'p1.password');
    expect(await store.read(ref), 'topsecret');
  });
}
