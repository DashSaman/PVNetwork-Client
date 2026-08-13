# Known Issues / Failed Attempts

Last updated: 2026-08-14 (+03:30)

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
