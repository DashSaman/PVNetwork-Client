# PVNetwork Agent Continuation Protocol

This repository is the source of truth for continuation. Before changing code or CI, every agent MUST read:

1. `docs/PROJECT_STATE.md`
2. `docs/KNOWN_ISSUES.md`
3. the latest GitHub Actions runs for `.github/workflows/xray-mobile-ci.yml` and `.github/workflows/universal-release.yml`

## Non-negotiable workflow

- Never ask the user to write or debug code that can be handled in this repository.
- Do not repeat a failed build strategy without new evidence.
- For every failed CI run, record: run ID, job ID, commit SHA, failed step, observed error (or explicitly state when GitHub did not expose the detailed log), root-cause hypothesis, patch, and next check in `docs/KNOWN_ISSUES.md` and update `docs/PROJECT_STATE.md`.
- Continue the loop: inspect -> patch -> push -> CI -> inspect until a real installable APK artifact succeeds.
- A UI-only/shell APK is NOT a final VPN client.
- Final Android gate requires a real VPN tunnel engine and configuration import/connect path. Never relabel a shell/preview APK as final.
- Never embed OV-Panel/3x-ui administrator credentials or private backend secrets in the app.
- Keep signing secrets out of Git. Debug signing may be used for CI installable APKs; release keys belong in GitHub Secrets.
- Preserve third-party license notices and source obligations for reused GPL/open-source components.

## Product direction

PVNetwork is a public + commercial VPN client. Public users can import their own supported configurations; PVNetwork users can later authenticate and receive products/profiles through the PVNetwork gateway API. Commercial catalog names must be decoupled from tunnel protocols. Tunnel engines are registered through a protocol/engine abstraction rather than hard-coded product categories.

## Task tracker

Status legend: `[x]` done · `[~]` in progress · `[ ]` open. Update this table in the same commit that changes code.

### Phase A — Core data & storage
- [x] A1 Cross-platform Flutter foundation under `universal/`
- [x] A2 `VpnCoreAdapter` contract locked (`universal/lib/core/engine/vpn_core_adapter.dart`)
- [x] A3 `PVProfile` v2: transport/security/dnsPolicy/routingPolicy/engineRequirements/secretRefs + v1 back-compat
- [x] A4 `ProfileDetector`: 13 URI schemes + JSON/YAML/.ovpn/.conf detection, v2 field population, per-family engine requirements
- [x] A5 `ProfileRepository` on `flutter_secure_storage` + `SecretStore` indirection (`$ref{field}` placeholders)
- [x] A6 Host bootstrap script (`scripts/setup_host_projects.sh`) for local dev and CI
- [x] A7 Android host patches: `PvxrayBridge`/`PvxrayPlugin`/`PVVpnService`/`MainActivity` under `universal/patches/android/`

### Phase B — UI shell wired to real state
- [x] B1 Responsive shell, exact branding, page frame
- [x] B2 Home / Connections / Add Connection / Account / Store / Settings pages
- [x] B3 `PVController` real connection lifecycle (connect/disconnect/switchProfile/reconnect)
- [x] B4 `EngineRegistry`: profiles resolve to adapters; unknown engines refused honestly
- [x] B5 Live status: link state, error banner, latency + traffic stats polling
- [x] B6 Clipboard/file/subscription/manual import paths
- [x] B7 Desktop platforms degrade gracefully (engine reported unavailable, no fake states)

### Phase C — First-party Xray engine
- [x] C1 `core/xray-mobile/pvxray`: version/validate/start/stop/isRunning + InitEnvironment/QueryUplink/QueryDownlink/ResetStats/MeasureDelay (+ Go tests)
- [x] C2 Xray-core version pinned in `go.mod`; AAR checksum emitted by CI (`SHA256SUMS.txt`)
- [x] C3 `XrayConfigBuilder`: VLESS/VMess/Trojan/Shadowsocks/SOCKS/HTTP + REALITY/TLS + raw/ws/grpc/xhttp/httpupgrade + DNS strategies + routing (private-direct, bypassIR) + stats/policy
- [x] C4 `xray-mobile-ci.yml`: gomobile bind AAR artifact (green as of `87f82af`)
- [x] C5 `XrayAdapter` + `XrayMobileBinding` (MethodChannel contract) in Dart

### Phase D — Device-level verification (NEXT)
- [ ] D1 Run `universal-release.yml` on this branch; confirm Android job picks up the AAR artifact and the APK builds with the patched host
- [ ] D2 On-device E2E: import a real VLESS/VMess/Trojan/SS profile, grant VPN permission, verify live traffic through the tunnel (not just state flags)
- [ ] D3 Ship `geoip.dat`/`geosite.dat` assets for `bypassIR` routing (copy-to-app-data + `InitEnvironment` wiring)
- [ ] D4 Refresh stats latency probe path with `measureDelay` from the UI (manual "test latency" affordance)
- [ ] D5 Update `docs/PROJECT_STATE.md` + `docs/KNOWN_ISSUES.md` with the run IDs and outcomes; only then update release naming per the release rule


### Stage 0 — universal client reliability/security (2026-10-27; PR #1, IN PROGRESS)

- [~] S0-1 Replace broken Android AGP9 file-picker implementation; CI Android APK proof pending.
- [~] S0-2 Always build required Xray native AAR from exact checkout and verify checksum/class rather than downloading an unrelated CI artifact; current pull-request run pending.
- [~] S0-3 Prevent app UID outbound VPN loop via `VpnService.Builder.addDisallowedApplication(packageName)`; still requires on-device packet and per-app isolation tests.
- [~] S0-4 Remove the unauthenticated HTTP proxy previously used to test latency; secure replacement probe pending. UI currently receives latency unavailable (-1), not fake success.
- [~] S0-5 Protect newly imported raw configuration and subscription URL by encrypted SecretStore references; test added. Existing stored legacy profiles still require explicit safe migration.
- [~] S0-6 Correct deletion of secret references including legacy namespace and validate resolved config; unit regression added.
- [ ] S0-7 Android VPN real-device E2E proof: test TUN fd ownership, outbound socket exclusion, DNS/IPv6, link resilience and proper connected/disconnected state.
- [ ] S0-8 Implement secure latency measurement, controller cancellation while connecting and multi-adapter lifecycle.
- [ ] S0-9 Merge only after validated release gates and recorded CI/device receipts. PR: https://github.com/DashSaman/PVNetwork-Client/pull/1

Do not promote any Stage 0 item from in-progress to PASS merely because source changed. Details: `docs/audits/2026-10-27-ANDROID-DEFECTS.md` and `docs/product/PVNETWORK_UNIVERSAL_FEATURE_MASTER_2026-10-27.md`.
