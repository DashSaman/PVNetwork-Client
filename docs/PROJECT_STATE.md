# PVNetwork Project State

PVNetwork version: `0.3.0-dev`
Branch: `main`
Last updated: 2026-08-14 (+03:30)

## Last verified state
- `v0.2.0-alpha.1` cross-platform foundation build completed successfully for Android, Windows, Linux, macOS and unsigned iOS.
- That release is **not a usable VPN client**: it has no real profile/import/account/store workflow and no enabled tunnel engine.
- User testing confirmed generic Flutter branding and insufficient UI; do not present that release as the product.

## Current milestone
Research-complete gate → production client foundation → first real networking adapter.

## Last completed work
1. Protocol/capability matrix created: `docs/PROTOCOL_MATRIX.md`.
2. Mature reference clients reviewed: `docs/research/COMPETITOR_MATRIX.md`.
3. Upstream failure lessons/regression targets recorded: `docs/research/COMPETITOR_LESSONS.md`.
4. Core strategy recorded: `docs/CORE_SELECTION.md`.
5. Production information architecture recorded: `docs/UX_BLUEPRINT.md`.
6. Official logo rules locked: `docs/BRAND_GUIDELINES.md`.

## Working features
- Cross-platform Flutter build pipeline.
- Android/Windows/Linux/macOS build runners.
- unsigned iOS build runner.
- Existing native Android prototype parses basic config text, but it is not the target product UI.

## Experimental / incomplete
- Cross-platform UI under `universal/`.
- Protocol detection/import design.
- Backend contract for PVNetwork account/catalog/services.

## Broken / not implemented
- Exact official logo is not yet applied to all build targets.
- No production Connections manager.
- No complete Add Connection flow.
- No persisted canonical `PVProfile` model.
- No functional PVNetwork Login/Register UI connected to a backend.
- No Store UI connected to backend.
- No enabled Xray/OpenVPN/WireGuard adapter.
- Connect must therefore remain disabled/unavailable until a real adapter reports a tunnel.

## Current task
Rebuild `universal/` from the research documents:
- responsive mobile/desktop shell
- exact PVNetwork black/gold branding
- Home / Connections / Add Connection / PVNetwork / Store / Settings
- local `PVProfile` persistence
- clipboard/file/subscription/manual import foundation
- English + Persian/RTL first-class
- prepare stable `VpnCoreAdapter` boundary

## Next exact networking task
After the profile/UI foundation builds and tests cleanly, implement the first real Xray-core adapter starting with VLESS/REALITY, VLESS TLS, VMess and Trojan. A connection is not marked successful until real traffic and cleanup are verified.

## Release rule
Do not publish another user-facing release merely because the UI builds. The next download offered as a usable VPN client must contain at least one real, verified connection adapter.
