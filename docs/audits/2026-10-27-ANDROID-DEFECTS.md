# PVNetwork independent defect audit — 2026-10-27

Repository: DashSaman/PVNetwork-Client
Reviewed branch and head: main @ d6a4aaccbae304ed4acc7c56a621850e969871c6 (last head commit dated 2026-09-17).
Status: source-and-CI audit; NO fresh Android/desktop builds, no physical-device tests, and no production-network validation were performed in this review.
Severity: P0=release blocker / critical reliability, P1=high priority, P2=important usability/maintenance.
Evidence classification: CONFIRMED_SOURCE, CONFIRMED_CI, HIGH_RISK_NEEDS_RUNTIME, FEATURE_MISSING.
Do not confuse the success of host compilation with an interoperable VPN connection.

## Current authoritative evidence

- Latest universal CI 35177021596: FAILED, Android job 105060854421; other platform jobs passed build/analyze/tests only.
- Android Java compiler failure: GeneratedPluginRegistrant.java references com.mr.flutter.plugin.filepicker.FilePickerPlugin, which cannot be found. Dependency is file_picker 11.0.2 in universal/pubspec.yaml. The same failure is documented upstream at https://github.com/vicajilau/flutter_file_picker/issues/2002 and https://github.com/vicajilau/flutter_file_picker/issues/2200 . Assess a supported updated plugin and migrate changed v12+ API, or choose a proven AGP-compatible version; do not assert a fix before green Android CI.
- Xray AAR CI 35175954590: SUCCESS. Its success is a compile/unit receipt, not a tunneled-packet/device receipt.
- Latest GitHub Release is v0.2.0-alpha.1, described as an engine-free foundation. README says V0.3 SFA/sing-box, while PROJECT_STATE and AGENTS describe the currently pursued first-party Xray Flutter path. This contradiction should be reconciled.
- docs/KNOWN_ISSUES.md last enumerates KI-010, but the latest KI-011-class file_picker failure is not recorded there.

## P0 release blockers

D-001 [P0][CONFIRMED_CI] Android release build fails at Java plugin registration. Source: universal/pubspec.yaml; run 35177021596/job 105060854421. DoD: pinned Flutter/AGP/plugin combination; Android APK CI green and smoke install on hardware.

D-002 [P0][HIGH_RISK_NEEDS_RUNTIME] Outbound VPN socket protection / routing loop not established. PVVpnService routes 0.0.0.0/0 and ::/0; no explicit VpnService.protect() or equivalent native socket binding is visible in the Android patch or Go wrapper. Android documents routing loops without socket protection: https://developer.android.com/reference/android/net/VpnService . DoD: verify all core outbound UDP/TCP sockets avoid the app tunnel, check connectivity in packet captures, DNS and IPv6, test loss/restore of underlying network. Do not treat absence of protect in a limited source inspection as proof of runtime loop.

D-003 [P0][CONFIRMED_SOURCE] Artifact/core version coherence is fail-open. universal-release.yml finds latest successful xray-mobile-ci AAR by workflow status rather than immutable current commit; download-artifact has continue-on-error true and setup_host_projects.sh explicitly allows building without the AAR. DoD: consume an immutable SHA/checksum-matched AAR, fail Android packaging when absent, attest core version/hash and verify plugin registration.

D-004 [P0][FEATURE_MISSING] No physical-device, end-to-end import -> permission -> authenticated tunnel -> bidirectional traffic -> DNS -> disconnect receipt. docs/PROJECT_STATE.md and AGENTS.md record Phase D pending. DoD: real test endpoint and hardware evidence for each enabled protocol/transport/OS combination before calling it supported.

D-005 [P0][CONFIRMED_SOURCE] Connecting cannot be cancelled from PVController.disconnect(): isBusy includes connecting, so disconnect returns immediately; Home button is disabled while busy. In native PvxrayPlugin pendingStart can remain outstanding if service never returns success/failure. DoD: cancellable/timeout-bounded startup and robust exactly-once callback settlement, with regression tests for quick connect/disconnect, permission denial, foreground service failure and core start hang.

## P1 high priority defects

D-006 [P1][CONFIRMED_SOURCE] Secret deletion prefix mismatch: ProfileRepository.deleteProfileSecrets passes prefix pvnetwork.secret.<profileId>. while SecureStorageSecretStore.deletePrefix strips pvnetwork.secret. from enumerated keys before comparing. This prevents intended matching; verify and fix explicit ref deletion/cleanup. The currently stored profile document itself also retains raw credential-bearing URIs.

D-007 [P1][CONFIRMED_SOURCE] Import path does not extract credentials to secret references. PVController.addRaw directly creates PVProfile from ProfileDetector.toProfile and persists its rawSource, without invoking writeProfileSecret/redaction. Flutter secure storage encrypts stored records, but the claimed profile secret separation is not active for this flow. DoD: secret extraction, safe serialization/export, migration, no password leakage into logs or diagnostics.

D-008 [P1][CONFIRMED_SOURCE] Controller assumes one fixed engine: connect selects registry.forProfile, but disconnect(), refreshStats() and adapter event subscription use constructor-level _adapter. This will misbehave when independent OpenVPN/WireGuard/sing-box adapters are added. DoD: track per-session active adapter and cleanup stale session events.

D-009 [P1][CONFIRMED_SOURCE] Subscription URL import merely stores one URL-shaped PVProfile; no remote fetch, refresh, authentication, format normalization, node expansion, expiry or transactional update exists. The resulting raw https:// URL is not a working outbound. DoD: secure subscription manager with conditional refresh, caching, ETag, TLS validation, merge/dedupe and failed-refresh rollback.

D-010 [P1][CONFIRMED_SOURCE] Multiline bundle import returns one 'Subscription bundle' object with entries count, not individual connection profiles. Full Xray/sing-box JSON is classified but not converted into runnable outbound config. Clash YAML is classification-only and requires future Mihomo adapter. DoD: deterministic lossless/visible-loss parsing, individual profiles, fixtures for all formats.

D-011 [P1][CONFIRMED_SOURCE] Settings language/theme controls mutate widget-local state only. MaterialApp in universal/lib/main.dart is not given locale, themeMode, a localization delegate or controller-driven settings. Global UI strings are English literals despite nine-language marketing inherited from the older Java shell. DoD: actual persisted app-wide fa/en locale, tested RTL and LTR, theme changes apply instantly.

D-012 [P1][CONFIRMED_SOURCE] QR 'Scan QR' shows a not-enabled snackbar; Account and Store show static placeholders. They are not implemented customer functionality. DoD: camera import, backend contract/login/entitlement/catalog tested independently; never embed administrative panel credentials in shipped client.

D-013 [P1][CONFIRMED_SOURCE] OpenVPN, WireGuard, Hysteria2, TUIC and full Mihomo engine adapters are not registered in the Flutter client. Recognizing input formats is not the same as connecting. DoD: protocol-by-protocol adapters and actual device data-path tests.

D-014 [P1][HIGH_RISK_NEEDS_RUNTIME] TUN ownership and restoration: PVVpnService.detachFd transfers descriptor ownership while still assigning it to tun; Stop/onDestroy does not demonstrate deterministic close of the detached raw descriptor, and START_STICKY with null intent tries an empty configuration. Need lifecycle and file-descriptor leak tests, revoke tests, process death and background restarts.

D-015 [P1][HIGH_RISK_NEEDS_RUNTIME] Android tunnel status becomes Connected after start/ TUN establishment; no demonstrated traffic proof before success UI, and periodic health check does not reconcile state if native core dies. DoD: distinguish interface established / core running / authenticated / data-path working, verify connection watchdog and transition handling.

D-016 [P1][CONFIRMED_SOURCE] XrayConfigBuilder hardcodes IPv4 queryStrategy UseIPv4, fixed DoH providers, private CIDR bypass, fixed health port and only limited routing presets. Unsupported fields can be lost on conversion, and routing + DNS leak behavior are not device-verified. DoD: per-profile DNS/routing, IPv6, test DNS/UDP/WebRTC leakage, configurable probes and collision handling.

D-017 [P1][CONFIRMED_SOURCE] AAR reflection probes guessed class names in PvxrayBridge; no artifact-based generated namespace/API contract test proves a class resolves before packaging. DoD: inspect bound AAR class list, compile-time adapter or deterministic reflection test, runtime handshake.

D-018 [P1][CONFIRMED_SOURCE] Unsupported/malformed import has poor granularity: entire profile often accepted as metadata-only; full JSON/YAML/OVPN import does not mean runnable. Some protocol options in Xray builder explicitly throw not implemented. DoD: fail closed with field-specific error report and support matrix by exact transport/security.

## P2 quality and release risks

D-019 [P2] Only four tiny Flutter unit test files; no integration/device/long-run release gates, fuzzing, race testing, network changes or secrets migration suite in this repository tree.
D-020 [P2] No release signing/distribution/testflight/store claims justified by current build artifacts; unsigned iOS runner app is not an installable, signed VPN extension.
D-021 [P2] The old SFA/sing-box README and legacy Android Java shell create misleading dual paths. Choose one authoritative production build, archive legacy experiments and update documentation and CI.
D-022 [P2] Required open-source license, commercial redistributability, SBOM, pinned binary hashes, privacy/store declarations and latest advisories must be verified per binary; never copy competitor GUIs or GPL code without license approval.

## Immediate dependency-ordered fixes

1. Make Android CI reproducible and green; address the known file_picker/AGP compatibility failure with a tested migration and immutable lockfiles.
2. Fail-closed artifact provenance: exact Xray AAR built from locked source/hash, verify class/package before APK upload.
3. Instrument on-device TUN/socket exclusion, lifecycle, permission, DNS and data-path tests; fix any observed routing loops or fd leaks.
4. Repair controller cancellation/active adapter/session state and add deterministic asynchronous race tests.
5. Repair secret extraction and deletion, then subscription manager + fully functional QR/file/multi-profile import.
6. Add engine adapters in manageable slices (Xray validation first, then OpenVPN/WireGuard, then chosen sing-box/Mihomo coverage).
7. Restore real locale/RTL, theme, diagnostics, account/store backend and quality release gates.

## Acceptance / proof policy

- Source inspection != compiled.
- Compiled != installable.
- Installable != real connected.
- Tunnel established != DNS/IPv6/WebRTC leak-free.
- Upstream engine support != PVNetwork platform support.
- Only promote a capability when import, config validation, actual payload return path, DNS/routing, network change, stop/reconnect and device evidence pass.
- Preserve all fixes as source+tests with CI run, device model/OS, reproducible trace and release capability matrix.
