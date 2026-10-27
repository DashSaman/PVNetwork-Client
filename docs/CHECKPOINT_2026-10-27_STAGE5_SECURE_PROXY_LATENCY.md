# PVNetwork Stage 5 — secure internal Xray HTTPS data-path probe

Date: 2026-10-27. Branch: feat/stage0-reliability-20261027. Draft PR #1.
Roadmap: docs/product/PVNETWORK_UNIVERSAL_FEATURE_MASTER_2026-10-27.md.

## Verified baseline

Actions 40446115250, commit 5cc3fac4aa1df340ea6123679f4502d8feb4cd50: 7/7 PASS (Xray generated configs, local VLESS data-path, Android APK, Android x86_64 emulator startup, Windows, Linux, macOS, unsigned iOS). Real Android VPN TUN + public-server handshakes are NOT verified.

## New work committed

- core/xray-mobile/pvxray/pvxray.go: reinstated MeasureDelay, using Xray's **in-process core.Dial**, forced outbound tag proxy via session.SetForcedOutboundTagToContext, bounded HTTPS request with redirect refused and no listening localhost HTTP/SOCKS port. Security: exported gomobile API only allows the fixed HTTPS URL https://www.gstatic.com/generate_204; arbitrary HTTP/private/cloud metadata addresses are not accepted, and failures yield -1.
- core/xray-mobile/pvxray/vless_loopback_test.go: test the new in-process probe against the disposable localhost VLESS server; proof requires actual response through Xray, not just core startup.
- core/xray-mobile/pvxray/pvxray_test.go: reject SSRF via arbitrary URLs and local/metadata endpoints.
- universal/lib/core/engine/xray_adapter.dart: advertise measureDelay capability, coalesce concurrent probes and cache last measurement for 30s because stats poll every 3s. Reset latency on connection stop/start; test included in universal/test/controller_test.dart.
- universal/lib/ui/home_page.dart: show independent 'Proxy data path — HTTPS probe verified/Not verified' status instead of claiming verified external Internet solely from core isRunning.

## Current live CI receipts

- Exact-head run initially observed: 40524305440 on f9996526acc55a1f902829d7b0bd832f93f06dbc.
- In that run, 'Pinned Xray / Flutter config contract' PASS, and the log includes the local VLESS test. The Android APK, emulator smoke and other OS jobs must be separately checked for final exact-head status.
- A local proxy-bound HTTPS check is NOT a real public-server connection and cannot prove all DNS/IPv6 or Android VpnService routing behaviors.

## Limits and next engineering gates

1. Verify that 40524305440 completes all 7 jobs SUCCESS at exact SHA; diagnose any failure.
2. Record real outbound health separately from native engine running (measureDelay returns -1 for unavailable/not verified; never interpret it as a definitive server failure when the fixed public probe is blocked).
3. Revisit default health endpoint strategy by region with strict allowlist and non-SSRF private egress semantics. Be explicit about user privacy and battery effects.
4. The highest remaining release blocker is real Android VpnService and TUN ingress/egress test on device or controlled emulator, then physical-device AND-001 through AND-024 in docs/ANDROID_REAL_DEVICE_ACCEPTANCE_2026-10-27.md. Include DNS, IPv4/IPv6 and cleanup.
5. Native system proxy/TUN on Windows/macOS/Linux and actual Apple Network Extension remain unimplemented; cross-platform UI builds are NOT VPN support.
6. Keep draft PR unmerged; no production or stable release until actual device E2E security gates.

## Reproduction

GitHub Actions 'Pinned Xray / Flutter config contract' runs Go VLESS localhost test against a disposable child-process server after Dart fixture generation. CI then builds the mobile AAR and Android app from the exact checkout, and Android emulator install-launch smoke is a separate dependent job.
