# Stage 3 — PVNetwork Flutter-to-pinned-Xray config contract

Branch: feat/stage0-reliability-20261027; draft PR #1. Full 503-item target catalog remains unchanged.

## Stage 2 trusted base

GitHub Actions run 40433925852 at commit edcd8251fb36dcf5a676f792fccbe3dae8be8e33: six-job PASS (Android APK; Windows, Linux, macOS; unsigned iOS; Android emulator startup). This does NOT prove real VPN traffic, permission or DNS.

## Stage 3 engineering deliverables

- universal/tool/export_xray_fixtures.dart: produce synthetic nonfunctional client profile JSON using the exact XrayConfigBuilder shipped in Flutter. Cases: VLESS REALITY + Vision; VLESS WebSocket TLS; VMess WebSocket TLS; Trojan TLS; Shadowsocks AEAD.
- core/xray-mobile/pvxray/generated_config_test.go: validate all generated configs via PVNetwork's actual pinned core.LoadConfig interface through ValidateConfig. Environment PV_REQUIRE_XRAY_FIXTURES=1 enforces mandatory complete fixture set; ordinary AAR unit tests skip until Dart fixtures are generated.
- .github/workflows/universal-release.yml: new hard gate to run Dart exporter, then native Go config validation before Android APK release job. No customer credentials are used. Fail on any parser error.
- Official baseline references: https://xtls.github.io/en/config/outbounds/vless.html ; https://xtls.github.io/en/config/transport.html ; https://github.com/XTLS/Xray-core .

## Evidence and limitations

The first Stage 3 CI run is pending at commit 4274f1a2e0c9a2660cc35027527a7a172a0481ec. Do not claim PASS before the current run completes. Passing means accepted by this exact pinned Xray parser — NOT handshake, real traffic, DNS, UDP, native TUN, or physical-device tests.

## Exact next action

1. Read the latest PR #1 Actions run and its native Xray config fixture test output. Fix unsupported/invalid actual configuration fields using pinned upstream Xray evidence; never weaken test assertions to fabricate PASS.
2. Confirm the new exact-head full CI matrix succeeds, including Android emulator smoke and JNI packaging.
3. Continue real test-device VLESS/REALITY traffic and DNS/IPv6 tests from docs/ANDROID_REAL_DEVICE_ACCEPTANCE_2026-10-27.md. The physical-device gate remains open.
4. Keep PR in draft, do not merge into main or ship a user-facing VPN until the genuine connection and security gates pass.
