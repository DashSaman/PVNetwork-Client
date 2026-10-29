# PVNetwork Stage 0 / Android real-device acceptance

Scope: PR #1 `feat/stage0-reliability-20261027`. This file defines **testing yet to be performed**, not proof of successful tunneling.

## Proven so far

- Universal CI `40425906428` passed all five build jobs at its recorded PR SHA (not evidence of physical VPN connectivity).
- Android log from that run confirms `pvxray/Pvxray.class` and `jni/arm64-v8a/libgojni.so` exist inside generated AAR.
- The former Android Kotlin bridge looked for wrong Java packages and could never resolve `pvxray/Pvxray`. Stage-2 PR patch replaces guessing/reflection with a compile-time `pvxray.Pvxray` import. Its latest Android APK CI is the next immediate gate.
- Since stage-0 removed unauthenticated local HTTP probe, core-dependent latency may show unknown rather than a falsely healthy latency.

## Before hardware tests

1. Use only an APK artifact from a green CI run at the **exact tested commit**, not the prior v0.2 shell or an artifact from another branch.
2. Confirm APK package identity and architecture; record SHA256, build time, device model, Android version, ABI, mobile network and Wi-Fi environment.
3. Use a **dedicated authorized test VPN server** with disposable credentials and no customer subscription token. Never put production secrets in tickets, screenshots, or CI logs.
4. Confirm that the exact ABI contains native `libgojni.so`, the `pvxray.Pvxray` bridge links, and the app actually asks for Android VPN permission.
5. Back up/export test-device relevant configurations before exercising failure cases.

## Mandatory hardware scenarios

| ID | Action | Required PASS evidence |
|---|---|---|
| AND-001 | Fresh install and launch | Correct logo/package; no startup crash or missing native class |
| AND-002 | Import VLESS/REALITY | No secret logged, parsed preview accurate; secret still usable after app restart |
| AND-003 | Connect / allow VpnService | Native core starts, OS shows VPN, app state matches native state |
| AND-004 | Fetch IPv4 HTTPS endpoint through tunnel | Server sees expected VPN egress; response body marker verified |
| AND-005 | Fetch IPv6-capable endpoint | IPv6 routed per profile or clearly disabled without leakage |
| AND-006 | DNS from app and device | External resolver and DNS path match policy; no unplanned system DNS leak |
| AND-007 | UDP and QUIC-capable app | Traffic reaches correct target without loop/loss beyond tolerance |
| AND-008 | Start then cancel immediately | Eventually returns DISCONNECTED, no lingering VPN/process/adapter; bounded native start behavior required |
| AND-009 | Rapid repeated connect/disconnect 100 times | No duplicated sessions, fd leaks, stale callback or failed next start |
| AND-010 | Switch between two test VLESS servers | Old core session cleanly stopped; new server egress confirmed |
| AND-011 | Stop / disconnect | OS VPN indicator off, route and DNS restored, no background core leak |
| AND-012 | Wi-Fi → mobile → Wi-Fi | Reconnect policy respected and no direct-path leak |
| AND-013 | Lock/unlock and Doze/background | Notification and VPN service remain truthful; traffic resumes where allowed |
| AND-014 | Revoke VPN permission/another VPN | Clear reason code, no ghost CONNECTED, resources released |
| AND-015 | Kill app/core process | OS/network cleanup; no stuck full-device VPN route after restart |
| AND-016 | Local localhost probe port 19670 | No unauthenticated HTTP proxy reachable, especially from another app |
| AND-017 | Per-app routing exclusion | Excluded apps do not inherit access to unauthorized local proxy |
| AND-018 | Direct outbound loop protection | Verify core sockets use excluded UID or protected network, no self-TUN loop |
| AND-019 | Invalid cert / wrong REALITY key / expired token | Honest error with redacted diagnostics, no fallback to direct routing |
| AND-020 | Delete imported credentials / relaunch | Secret references deleted, no credential remnants in profile JSON or diagnostics |
| AND-021 | Legacy profile after upgrade | Transparent idempotent migration, existing profile still connects |
| AND-022 | Invalid and oversized imported config | Safe refusal, prior profile data intact |
| AND-023 | Battery and 1-hour+ sustained traffic | Measured CPU/RAM/fd/battery and packet-loss baseline, not an invented claim |
| AND-024 | QR, OpenVPN, WireGuard profiles | Where adapter not implemented, show truthful unavailable state and never claim connection |

## Suggested operator-side diagnostics

- `adb shell dumpsys connectivity` for VPN state and active network.
- `adb shell dumpsys activity services com.pvnetwork.vpn` for service lifecycle.
- `adb logcat -d -s AndroidRuntime:E` for crash signature. Redact all account/profile/server credentials and tokens before sharing.
- Correlate explicit server-side packet/echo markers with device timestamps. DNS leak testing needs both IPv4 and IPv6 paths, plus network-switch cases.
- Capture the last actual signed/verified APK SHA256 and CI job URL in this document. **A green UI status or a working HTTP 204 test is not sufficient proof.**

## Release gate

Do not merge PR #1 as a production-ready VPN, mark the feature catalog complete, or publish a user-facing version until AND-001–AND-020 are evidenced as applicable, P0 defects are resolved, and privacy/license/release-signing gates are met. Windows/macOS/Linux/iOS compilation alone does not imply native VPN support.

## Next engineering blockers

- Device-ready test endpoint and attached Android device, not accessible through current GitHub-only tooling.
- Native start timeout/cancellation requires a bounded Android-service/Go bridge contract; controller-level cancellation only waits for an in-flight native start to settle.
- Android TUN fd ownership/detach/close lifecycle must be traced on device; avoid speculative ownership fixes.
- Legacy secrets must be migration-tested against a real upgraded installation and a corrupted-store fixture.
