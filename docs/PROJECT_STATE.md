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
