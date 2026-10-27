# PVNetwork — Stage 2 native lifecycle checkpoint (2026-10-27)

Branch: `feat/stage0-reliability-20261027` / draft PR #1. Feature source: `docs/product/PVNETWORK_UNIVERSAL_FEATURE_MASTER_2026-10-27.md`.

## Resumed from previously verified CI

- **40429012502** at `0aa92512634c702aad0744cf97f5d664ef2d9520`: PASS on Android, Windows, Linux, macOS, unsigned iOS.
- **40431948797** at `7f5eaeeffde0b65b8359d20d9c5511dc2ca95063`: PASS, including first Android native single-worker service start design.
- Builds are NOT on-device or VPN traffic verification. Signed release/physical device checks remain open.
- Newest modified branch includes subsequent fixes; never transfer PASS from an older SHA to a new head. Consult live PR #1 exact-head Actions run before any merge.

## Stage 2 committed source changes

1. `universal/patches/android/PVVpnService.kt`: Move Xray native start/stop off Android main thread onto one ordered worker. Guard async starts with generation tokens, bind MethodChannel startup result to real core initialization and return a 20s bounded service-start error if it fails to settle. Refuse sticky empty-config restart.
2. Preserve Java `ParcelFileDescriptor` ownership rather than detaching a raw fd that upstream pinned Xray Android TUN does not close. Xray AndroidTun.Close currently returns without closing fd in exact upstream commit `5ca6f4b7d4dc`: https://github.com/XTLS/Xray-core/blob/5ca6f4b7d4dc/proxy/tun/tun_android.go . Stop native engine first, then close TUN. **Still requires device fd lifecycle/negative-case testing**.
3. `universal/patches/android/PvxrayPlugin.kt`: Stop requests no longer return success until worker confirms native stop + TUN close; handles failure explicitly. Expensive native version/validation/stats/state queries go to a background query worker to prevent main-thread blocking on Go mutex.
4. `universal/lib/core/engine/xray_mobile_binding.dart`: Time-bound native start/stop awaits (defaults 25s/12s; injectable shorter durations for tests). Timeout means *unknown cleanup*, not verified disconnected. User permission dialog is separately waited on.
5. `universal/lib/core/engine/xray_adapter.dart`: Attempt cleanup when native start partially succeeds before throwing; do not mark disconnected if native Stop throws; degraded stats reset and disabled latency probe do not fabricate failure of a healthy running core.
6. `universal/lib/controller.dart`: Refuse to start a second native engine after failed previous Stop; switching or deleting current profile does not destroy state/credentials while native cleanup failed.
7. `universal/test/controller_test.dart`, `universal/test/controller_lifecycle_test.dart`, `universal/test/xray_mobile_binding_timeout_test.dart`: Add regression tests for partial start, failed stop, timeout, pending/native late events, preserved credentials, and multi-adapter switching.
8. `.github/workflows/universal-release.yml` and `scripts/android_emulator_smoke.sh`: Add dependent Android x86_64 emulator install/launch check with fatal-Java-crash signal from the **same CI APK**. It tests basic install/startup only, not actual proxy tunnel, DNS, VPN permission or outbound IP.

## Design boundaries and remaining gates

- The 20s service-start deadline bounds UI completion. It **does not forcibly preempt a hung Go native call**. The same worker is responsible for queued cleanup if Go returns. Dart awaits also have bounded timeouts, but a genuinely stuck native call may remain until process death. Hard cancellation/recovery still needs isolated-process design or platform-safe native cooperative cancellation.
- Current notification remains a *service starting* notification; no proof yet of complete network path.
- With `AndroidTun.Close()` implementation, TUN ownership transfer must be tested for double-close/errors on failed partial init, revoke, process death and rapid restart. Do not mark the fd issue solved on source inspection alone.
- Core `isRunning()` means local engine running, **not** successful VLESS handshake / DNS / Internet egress.
- The old localhost HTTP proxy test path stays disabled (no unauthorized local proxy). A secure proxy-bound latency probe remains on backlog.
- Android physical-device tests AND-001…AND-024 in `docs/ANDROID_REAL_DEVICE_ACCEPTANCE_2026-10-27.md` are not run.
- Failed native STOP must retain the active profile, secrets and an actionable error; reconnection should be blocked until cleanup verified.
- The new emulator job is not yet a PASS receipt until its actual run is green.
- Do not merge PR #1 or publish a 'usable VPN' release without exact-head CI green, real-device VPN datapath, DNS/IPv6, clean stop, security/privacy/license gates.

## Next non-repeating action

1. Read **latest exact-branch-head** Actions run, diagnose errors in new Flutter tests, Kotlin service, emulator as shown in logs, fix and rerun.
2. Once Android CI and emulator smoke pass, capture artifact version/sha and propose installing on an authorized Android device.
3. Use a disposable authorized VLESS/REALITY test server and complete AND-001…AND-024, especially actual egress/DNS/IPv6 and fd leak tests.
4. Continue the verified capability backlog only after native interop safety is established.

Do not repeat already verified stage-0 research or falsely mark unknown protocol/platform features green.
