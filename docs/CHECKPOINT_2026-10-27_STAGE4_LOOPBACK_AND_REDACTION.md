# PVNetwork Stage 4: semantic config, local VLESS data path, secret-safe errors

Branch: feat/stage0-reliability-20261027; PR #1 (draft, not production, not merged).
Date: 2026-10-27.

## Immutable verified previous evidence

- CI 40441126275 at d81320cc5e6f8f64524620efb9150ec62f620e94: all 7 jobs PASS, including Flutter/Xray config gate, APK, x86_64 emulator startup, Windows, Linux, macOS and unsigned iOS.
- Later CI 40444898506: pinned-core **semantic protobuf inspection** job PASS on intermediate source 06fa6f2e73e6cb851e4b2d8a1975c6457fe03f31, but whole run was cancelled by newer commits; don't use it as a full CI acceptance.
- These receipts do NOT prove a live VPN on a physical Android device.

## Source changes for Stage 4

1. `core/xray-mobile/pvxray/generated_config_test.go`: strengthen the existing fixture gate: inspect **compiled** protobuf transport, TLS/REALITY settings, Xray outbound family and actual VLESS/VMess endpoint + user fields; JSON decode or LoadConfig success alone is not enough.
2. `universal/lib/core/security/safe_error.dart`: safe user-facing exception mapping and conservative redaction for config URIs, access tokens, passwords and private-key blocks; sanitize no-auth/timeout errors without exposing core exception contents. Wired into `PVController` and `XrayAdapter`, with `universal/test/safe_error_test.dart` regression cases.
3. `universal/tool/export_xray_fixtures.dart`: add an eighth synthetic VLESS localhost-only fixture. This is safe only because the endpoint is private 127.0.0.1 and never sent to a public network.
4. `core/xray-mobile/pvxray/vless_loopback_test.go`: start a synthetic **local Xray VLESS server** on 127.0.0.1, start a client with the **actual Dart-produced VLESS outbound**, replace only the Android TUN inbound with test-only SOCKS, and verify an HTTP response marker crosses VLESS and returns correctly. Uses disposable UUID, localhost addresses and no customer credentials or external endpoints. It is a real **local protocol handshake/data-return** test, NOT Android VpnService tunnel E2E.
5. `.github/workflows/universal-release.yml`: both pinned-core contract checks and Android build stage must run semantic config test plus the VLESS local interoperability test when synthetic fixtures exist; fail before uploading APK.

## No false certification

- The new loopback test has been committed, but its PASS is not claimed until the exact latest Actions job executes successfully.
- End-to-end Android permission, TUN, IPv4/IPv6, DNS leak, Wi-Fi/mobile switch, failover, elapsed/battery, real external handshake and FD-lifecycle checks remain open. See `docs/ANDROID_REAL_DEVICE_ACCEPTANCE_2026-10-27.md`.
- Last observed exact PR head for this stage: 74d6418af19170b338aec3156b5b7f70670b5c48. A GitHub Actions run was queued/pending; inspect that precise SHA, not old passes.
- Do not merge the draft into main or publish a usable VPN release without latest-CI PASS, actual physical-device traffic tests and security/license compliance.

## Resume next action

1. Read the current run for head 74d6418af19170b338aec3156b5b7f70670b5c48 (or newer) and examine pinned Xray local test logs. If the Go runtime refuses a local inbound or handshake, correct the test/server fixture according to the pinned source; do NOT reduce assertions to greenwash.
2. Verify Flutter/Dart redaction tests, Android APK native AAR, emulator launch and all four cross-platform host jobs.
3. Record fresh exact SHA/CI evidence for each gate in the project state and issue tracker.
4. Proceed to authorized real-device Android VLESS/REALITY, DNS/IPv6 and packet tests. Separate Android physical tests from local loopback proof.
