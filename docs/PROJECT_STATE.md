# PVNetwork Project State

PVNetwork version: `0.3.0-dev`
Branch: `main`
Last updated: 2026-09-17 (+03:30)

## Last verified state
- `xray-mobile-ci.yml` green at `87f82af` (run 31756228916): first-party gomobile AAR builds with pinned Xray-core.
- `v0.2.0-alpha.1` remains a UI/import foundation only and must never be presented as a usable VPN client.
- Universal Flutter pipeline (`universal-release.yml`) validates `flutter analyze`, `flutter test`, and packages dev builds for Android/Windows/Linux/macOS/unsigned iOS on every `universal/**` push.

## Current milestone
First real tunnel engine end-to-end: core wrapper -> config generation -> adapter -> host wiring -> on-device verification (Phase D in `AGENTS.md`).

## Last completed work (this iteration)
1. `PVProfile` v2 schema with transport/security/dnsPolicy/routingPolicy/engineRequirements/secretRefs; v1 documents stay readable.
2. `ProfileDetector` fills v2 fields; each profile declares its required engine; unsupported families (Hysteria/Hysteria2/TUIC/WireGuard/OpenVPN/Mihomo) map to future adapters instead of Xray.
3. `SecretStore` indirection (secure-storage backend + `$ref{field}` placeholder resolution) wired through `ProfileRepository`.
4. `XrayConfigBuilder` completed: Shadowsocks/SOCKS/HTTP outbounds, DNS strategies with port-53 hijack, private-direct routing + opt-in `bypassIR`, stats/policy blocks.
5. `pvxray` Go wrapper extended: `InitEnvironment`, `QueryUplink`/`QueryDownlink`/`ResetStats`, `MeasureDelay` (through the running tunnel) + `MeasureDirectDelay`; Go tests added and executed by CI.
6. `XrayMobileBinding` (MethodChannel contract) + `XrayAdapter` implementing `VpnCoreAdapter` as pure Dart.
7. Android host patches (reflective `PvxrayBridge`, start-blocking `PvxrayPlugin`, `PVVpnService` foreground TUN service + permission flow) applied via `scripts/setup_host_projects.sh` in local dev and CI.
8. `universal-release.yml` Android job now downloads the latest AAR artifact from `xray-mobile-ci` and injects it into the build host.
9. Controller/HomePage: real connect/disconnect/migrate lifecycle, engine registry, live stats, honest errors.

## Working features
- Profile import (13 URI schemes, VMess JSON, Xray/sing-box JSON, Clash YAML, .ovpn, .conf), local secure persistence.
- Config generation for VLESS/VMess/Trojan/Shadowsocks/SOCKS/HTTP with REALITY/TLS and common transports.
- Connect/disconnect lifecycle against the native core on Android (requires the AAR artifact); graceful "engine unavailable" everywhere else.
- Live latency + traffic statistics once the tunnel is up.

## Experimental / incomplete
- Device-level E2E verification of the tunnel (Phase D) is pending.
- `bypassIR` routing needs bundled `geoip.dat`/`geosite.dat` assets.
- sing-box family (Hysteria/Hysteria2/TUIC), WireGuard and OpenVPN adapters are intentionally not started; profiles for them are refused with a clear message.

## Broken / not implemented
- `android-ci.yml` (legacy sing-box/SFA track, KI-002) still fails; it is superseded by the first-party `xray-mobile-ci` + `universal-release` path and is not a blocker.
- No production PVNetwork account/login/store backend integration yet.
- No signed release artifacts; debug/dev builds only until the release rule gate passes.

## Current task
Phase D: push this branch, watch `xray-mobile-ci` (Go tests) and `universal-release` (analyze/test + Android APK with AAR), then verify a real connection on a device and record run IDs in `docs/KNOWN_ISSUES.md`.

## Release rule
Do not publish another user-facing release merely because the UI builds. The next download offered as a usable VPN client must contain at least one real, verified connection adapter.

## 2026-10-27 external defect review (not a code fix)

- Head reviewed before documentation writes: d6a4aaccbae304ed4acc7c56a621850e969871c6.
- Universal Android CI remains FAILED at 35177021596; Go AAR workflow 35175954590 passed but there is no device traffic receipt.
- Independent prioritized source/CI findings and compiler root cause: docs/audits/2026-10-27-ANDROID-DEFECTS.md.
- Competitor benchmark and full feature acceptance backlog: docs/audits/2026-10-27-COMPETITOR-PARITY.md.
- New P0 review item: local unauthenticated HTTP health proxy accessible at 127.0.0.1:19670 and routed into the proxy outbound. Must be disabled/isolated and device-tested before public release.
- No production-readiness or verified device connection claim was added; application code unchanged during this audit.

## Product feature baseline — 2026-10-27

Feature inventory expanded to 503 individually trackable requested capabilities across 25 areas. See `docs/product/PVNETWORK_UNIVERSAL_FEATURE_MASTER_2026-10-27.md`. This is backlog only; no functionality is newly built or device-verified by the catalog update. All capability checkbox gates remain open unless separate evidence establishes success. Prioritize CI/safety and one actual device tunnel before broad feature parity.


## 2026-10-27 Stage 0 code branch / PR #1 (NOT MERGED)

- Branch: `feat/stage0-reliability-20261027`; PR: https://github.com/DashSaman/PVNetwork-Client/pull/1 .
- Replaced AGP9-broken `file_picker 11.0.2` with official `file_selector 1.1.0` and SAF-compatible read for .ovpn/.conf/.json/.yaml/.yml/.txt.
- Android workflow now compiles Xray AAR from its exact checked-out commit, verifies SHA256 and bound Java class, and is PR-triggered. No "latest unrelated AAR" success or allow-missing-native-core path is accepted for Android CI.
- Android VpnService own-UID exclusion added to reduce tunnel recursive socket risk. No native socket-protection device proof.
- Removed unauthenticated localhost HTTP health proxy inbound and its routing rule. Core MeasureDelay reports -1 until a secure alternative exists.
- New imports put raw config and subscription URL in SecretStore references; explicit deletion, legacy prefix and resolved-config validation corrected; regression tests committed.
- GitHub PR CI is RUNNING as of the in-chat review; first observed Linux result success. No Android APK pass or on-device VPN validation claimed yet.
- Safe follow-on: real device handshake/packet traces, native fd resource ownership, controller cancellation, legacy profile migration, Android signing/Store rules and secure latency probes.


## 2026-10-27 Stage 1 implementation follow-on (PR #1 remains DRAFT)

- Full five-job PR CI at `40425906428`: **SUCCESS** at commit `7f5a23f5d2a99cbb2fbc101134069a1feb9f6460`. This is a build proof, not real VPN connectivity. Native AAR found to export `pvxray.Pvxray`.
- Subsequently found a genuine startup blocker: Android bridge was reflectively looking up wrong package names; switched it to direct Java class linkage against `pvxray.Pvxray` and fail-closed native packaging.
- Controller lifecycle operation queue, cancel while connecting, active engine switching and stale event/stat rejection added, with unit tests. Native start hangs still need device-level bounded timeout and cancellation.
- Imported legacy profiles now migrate sensitive raw URIs/subscription tokens to SecretStore references on read, idempotently, with regression tests.
- Android plugin releases waiting startup result on stop/errors; UI Cancel is no longer disabled while CONNECTING.
- Dedicated real-device gate `docs/ANDROID_REAL_DEVICE_ACCEPTANCE_2026-10-27.md` defines 24 checks. No physical device or authorized server was accessible via the GitHub connector, so none was falsely marked passed.
- CI result for **latest branch head including compile-time native bridge** must be consulted before merge; prior green CI at an earlier SHA is not an approval to publish.
