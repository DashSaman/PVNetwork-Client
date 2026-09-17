# Known Issues / Failed Attempts

Last updated: 2026-09-17 (+03:30)

## KI-001 — V0.2 dedicated shell is not a VPN engine

- Existing `releases/v0.2/PVNetwork-VPN-v0.2-dedicated-debug.apk` is only the independent UI/config-import foundation.
- It must not be delivered or described as the final VPN client.
- Resolution: V0.3 build path uses real `sing-box-for-android` + pinned `sing-box` sources.

## KI-002 — Real Android CI run #7 failed in engine build

- Workflow: `PVNetwork Android CI`
- Run ID: `31739587023`
- Job ID: `94579420999`
- Commit: `935c4827247b42c6f8c25c1735528fd0c1ba5d98`
- Failed step: `Build dedicated APK from source`
- Runtime: ~9 minutes in the build step before exit code 1.
- GitHub check annotations expose only `Process completed with exit code 1`; the connector's job-log endpoint did not expose the textual tail during this investigation.
- The script at this commit builds pinned `sing-box v1.13.18` and `sing-box-for-android 0a401b6...`, installs `gomobile`/`gobind`, builds libbox, then builds SFA.
- Earlier commits already attempted stable Android API 36 and explicitly exposed gomobile/gobind on PATH. Do NOT repeat those same changes as a blind retry.

### Next diagnostic action

Instrument `scripts/build_real_android.sh` and CI so every major phase writes a persistent diagnostic log and, on failure, uploads it with `if: always()`. Pin Go instead of relying on the moving GitHub runner default. Split libbox and Android app phases so the exact failing command is visible in Actions annotations/artifacts.

## KI-003 — Moving toolchains are unacceptable

- Current real-build script relies on the runner-provided Go version and `GOTOOLCHAIN=auto`.
- This makes failures non-reproducible as GitHub runner images/toolchains move.
- Fix: install/pin the Go version required by the pinned sing-box source and record it in build metadata. Pin SDK/NDK/build-tools as well.

## KI-004 — CI workflow still names/stores V0.2 shell artifact

- `.github/workflows/android-ci.yml` still copies `app-debug.apk` to `PVNetwork-VPN-v0.2-dedicated-debug.apk` and its repository step describes tunnel engines as future work.
- This is stale and dangerous because a successful real V0.3 build could be mislabeled as the shell.
- Fix before final artifact: publish V0.3 real-engine filenames/metadata and never overwrite V0.2 history.

## KI-005 — Legacy sing-box Android CI track is superseded (decision, not a new failure)

- `android-ci.yml` (KI-002) remains red; the source-build sing-box/SFA pipeline is a dead end for V0.3.
- Decision: the first-party `core/xray-mobile` wrapper + `xray-mobile-ci.yml` (AAR artifact) + `universal-release.yml` (Flutter host) is the only engine delivery path.
- Do not invest retries into the sing-box build script unless a new requirement re-opens it.
- Next check: Phase D on-device verification (see `AGENTS.md` tracker); record run IDs here after the next pushes.

## KI-006 — gomobile Java package name for the pvxray AAR is assumption-based until first device log

- `PvxrayBridge.kt` resolves `Pvxray` reflectively over candidate packages (`github.com.pvnetwork.xray_mobile.pvxray`, `github.pvnetwork.xray_mobile.pvxray`, `com.pvnetwork.xray_mobile.pvxray`).
- gomobile derives the Java package from the Go import path; if none of the candidates match on device, every bridge call reports "pvxray core is not bundled" — the fix is adding the actual package string to the candidate list (one line), not a rebuild strategy change.
- Next check: D1/D2 on-device run; capture the AAR's actual package from the CI artifact if resolution fails.

## KI-007 — Run 35175324797 (xray-mobile-ci @ ca4ea41) failed: wrong stats API in pvxray.go

- Run ID: `35175324797`, Job ID: `105055655859`, Commit: `ca4ea41`
- Failed step: `Resolve and test Go wrapper`
- Observed error (GitHub exposed full log):
  - `pvxray.go:135/137/139/141/143`: `stats.ManagerType` undefined in `app/stats`; `impossible type assertion: mgr.(stats.Manager)` — the `Manager` interface lives in `features/stats`, `app/stats` only ships the implementation.
  - `pvxray.go:157`: `Counter has no field or method Get` — the interface method is `Value()`.
- Root cause: imported `app/stats` instead of `features/stats` for the interface types.
- Patch: switch import to `features/stats`, use `stats.ManagerType()` + `counter.Value()`.
- Next check: rerun of `xray-mobile-ci.yml` on the fix commit must go green through `gomobile bind`.

## KI-008 — Run 35175324789 (universal-release @ ca4ea41): analyzer lints + rigid gradle edit

- Run ID: `35175324789`, Commit: `ca4ea41`
- Failed jobs/steps and observed errors:
  - Linux/iOS/macOS `Validate and build...`: `flutter analyze` exited 1 with 3 issues — `unused_import: page_frame.dart` (warning, home_page.dart:6) + `unnecessary_import: dart:async` and `non_constant_identifier_names: XrayAdapterForTest` (infos, controller_test.dart). Note: the Windows runner succeeded with the same code — runners resolved different Flutter stables, and the newer one treats the infos/warning as fatal. Do not rely on per-platform analyzer leniency; keep analyze at zero issues.
  - Android `Generate Android host`: `AssertionError: unexpected build.gradle.kts layout` — the setup script asserted a literal `dependencies {` marker which the current Flutter template does not contain.
- Root cause: (a) PageFrame was dropped from HomePage during the real-connect rewrite, leaving its import unused; test file carried an unnecessary import and a non-lowerCamelCase helper; (b) script edit was marker-fragile.
- Patch: re-wrap HomePage content in `PageFrame`, drop `dart:async`, rename helper to `xrayAdapterForTest`; gradle edit now uses a regex with an append-new-block fallback; manifest patch also declares `foregroundServiceType="systemExempted"` + FGS/POST_NOTIFICATIONS/INTERNET permissions (pre-empting Android 14 startForeground crashes).
- Next check: rerun of `universal-release.yml` must pass analyze on all four runners and build the APK with the AAR wired in.

## KI-009 — Run 35175954550 (universal-release @ b47abd5): Android job failed on generated widget_test.dart

- Run ID: `35175954550`, Job ID: `105057589728`, Commit: `b47abd5`
- Failed step: `Validate and build APK`
- Observed error: `test/widget_test.dart:16:35 • creation_with_non_type — The name 'MyApp' isn't a class`
- Root cause: the Android job now copies `universal/test` before running `setup_host_projects.sh`; `flutter create` then adds the default `widget_test.dart` (which references the non-existent `MyApp`) into the copied suite. The other platform jobs still use the old inline flow with `rm -rf buildhost/test` and stayed green: iOS unsigned, macOS, Windows x64, Linux x64 all passed analyze + test + build.
- Patch: `setup_host_projects.sh` removes `test/widget_test.dart` right after `flutter create` (covers CI and local dev).
- Next check: Android APK job on the next run must reach `flutter build apk` and package `PVNetwork-Android-dev.apk` with the AAR wired in.
