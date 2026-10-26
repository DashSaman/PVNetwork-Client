# PVNetwork competitor capability benchmark and parity backlog — 2026-10-27

Project: DashSaman/PVNetwork-Client, base SHA d6a4aaccbae304ed4acc7c56a621850e969871c6.
Scope: a single branded consumer client supporting modern proxies and traditional VPNs. Do not promise 'every feature on every OS': platform APIs, license, security and Store restrictions require an explicit per-platform capability contract.
Current PVNetwork status: Android Xray implementation candidate, current APK CI red and no proven device tunnel; desktop/iOS packages are UI shells; other engines are unimplemented in this codebase.

## Competitors, primary evidence and lessons

- Karing: https://github.com/KaringX/karing — Clash/v2ray/sing-box subscriptions, pooled node selection, customizable routing and node groups, geo IP/site/ACL, advanced import/backup and WebDAV/LAN/iCloud sync.
- Hiddify: https://github.com/hiddify/hiddify-app — low-friction connection UX, delay-based node selection, TUN, broad modern proxy coverage, remote profiles and automatic refresh.
- v2rayNG: https://github.com/2dust/v2rayNG — Android Xray core and profile lifecycle, geoip/geosite update, professional VLESS/VMess/Trojan diagnosis, signed artifact verification.
- v2rayN: https://github.com/2dust/v2rayN — desktop Xray/sing-box interface, subscriptions, advanced platform controls.
- FlClash: https://github.com/chen08209/FlClash — multi-device Flutter/Mihomo, proxy groups, rule sets, request/DNS views, quick actions, WebDAV backup and TV/keyboard UX.
- Clash Verge Rev: https://github.com/clash-verge-rev/clash-verge-rev — desktop system proxy, TUN, profile merge/script, visual node/rule editing, logs, tray and WebDAV sync.
- NekoBox for Android: https://github.com/MatsuriDayo/NekoBoxForAndroid — expert sing-box-oriented import/subscription and per-app routing; evaluate known local SOCKS access risk: https://github.com/MatsuriDayo/NekoBoxForAndroid/issues/1197 .
- Happ: https://github.com/Happ-proxy/happ-desktop — Xray-based multi-platform Xray profile and rule-oriented proxy UI; official product feature summary, not reusable app source.
- OpenVPN Connect: https://openvpn.net/connect-docs/android-installation-guide/ — .ovpn, inline/external certificate/auth flows, Always-on, Quick Settings, authentication and route/IPv6 semantics.
- Amnezia VPN: https://github.com/amnezia-vpn/amnezia-client — WireGuard/OpenVPN/IKEv2/AmneziaWG and self-hosted VPN provisioning (distinct operator-facing feature; no unsafe credential embedding).
- Official WireGuard: https://github.com/WireGuard/wireguard-android — WireGuard tunnel/profile workflow.
- Upstream engine coverage is NOT an app parity claim.

## Required functionality — mark DONE only with release-gate receipts

### Parity group A: fundamentals [P0]
- [ ] CI green for Android with pinned builder, signed development artifact, immutable core provenance.
- [ ] Real device end-to-end tunnel working for first exact VLESS/REALITY capability.
- [ ] Permission, TUN, core socket protection, DNS, IPv4/IPv6 and packet return path proven.
- [ ] Connect, cancel, disconnect, reconnect, background/Doze/kill/restart and network switching proven with leak prevention.
- [ ] Real secret isolation, encrypted storage, logout/forget/backup semantics, safe logging.
- [ ] Accessible connected/error state with trustworthy diagnostics, not optimistic green indicator.

### Parity group B: import, profiles, subscription [P0/P1]
- [ ] VLESS, VMess (URI + encoded JSON), Trojan, Shadowsocks/SIP002 + supported 2022 ciphers.
- [ ] Hysteria2, TUIC, AnyTLS, ShadowTLS, relevant plugin families where exact-core supported.
- [ ] OpenVPN .ovpn (certificates, credentials, TLS auth, UDP/TCP, CRLs), WireGuard .conf and QR.
- [ ] Clash/Mihomo YAML providers, group selection, health-test; sing-box JSON; Xray JSON; unsupported-field audit.
- [ ] QR camera scan, QR render/share, clipboard, file, URI/deep link, multiline/b64 bundles, safe import preview.
- [ ] Subscription fetch/update/schedule/dedupe, ETag, User-Agent format negotiation, quotas, expiry and notifications, backup/rollback.
- [ ] Groups/folders, favorites, recent, search, sorting, rename/duplicate/delete, dedupe and profile export.
- [ ] Test delays for all nodes, batch testing, speed/throughput diagnostics, automatic best-server and failover.
- [ ] Multiple subscription formats for PVNetwork's existing 3x-ui/Mirza/PVNaive ecosystem without admin secrets.

### Parity group C: routing/DNS/control [P1]
- [ ] Global/Rule/Direct/Smart modes, GeoIP/GeoSite and ruleset updates with version/hash/rollback.
- [ ] Per-domain, IP/CIDR, process/app, destination port and country routing; proxy groups/selector/url-test/fallback where engine supports.
- [ ] Android per-app VPN and allow/bypass application choice; platform-specific split tunnel for supported OSes.
- [ ] Custom DNS, DoH/DoT, DNS-over-proxy, split DNS, FakeIP when core supports, IPv6 policy and DNS leak check.
- [ ] MTU, TCP/UDP, IPv4/IPv6, LAN bypass, captive portal and NAT64/dual-stack compatibility.
- [ ] Kill switch/Always-on only when real OS implementation and bypass behavior are validated.
- [ ] Desktop system proxy/TUN/elevated service/route rollback and tray helper as separate OS components.

### Parity group D: cross-platform and UX [P1]
- [ ] Android mobile/tablet/foldable, Android TV/Google TV remote-only UI with QR pairing, Windows/macOS/Linux and iOS/iPadOS with correct OS VPN APIs.
- [ ] First-class Persian RTL + English; other requested languages using actual localization delegates with mixed LTR IP/URL correctness.
- [ ] Dark/light/system themes, accessibility, screen-reader labels, reduced motion, high contrast and UI scaling.
- [ ] Home/dashboard, subscriptions, profile list/group, live requests/connections, logs, rules, DNS, diagnostics and settings.
- [ ] Simple vs expert mode, user-readable errors, upgrade/migration guide, onboarding, release notes.
- [ ] App background lifecycle, Quick Settings tile/shortcuts on supported OS, optional startup/reconnect toggle and power-aware telemetry.

### Parity group E: PVNetwork-specific commercial product [P1/P2]
- [ ] Optional PVNetwork account and secure device pairing; manual third-party profiles work without login.
- [ ] Backend API for existing service account, expiration, used/remaining quota, multiple locations and one-click secure sync.
- [ ] Purchase/renewal screens only after explicit billing policy, app-store rules and authorized API contracts.
- [ ] Node/pool selection and health based on operator-owned customer-facing subscription endpoints, not private admin APIs.
- [ ] Multi-panel and reseller integrations only through tightly scoped customer tokens; device concurrency policy enforced server-side.
- [ ] Optional support ticket/diagnostic sharing with explicit user consent and redaction.

### Parity group F: engineering/security/releases [P0/P1]
- [ ] Device interop matrix per protocol/transport/security/OS and real IPv4, IPv6, DNS, UDP/QUIC tests.
- [ ] Prevent localhost unauthenticated proxy exposure: apps excluded from VPN must not be able to use local helper proxy sockets to identify remote exit IP.
- [ ] Failure/regression matrix: revoke VPN, incoming call, sleep/Doze, Wi-Fi/mobile switch, captive portal, core crash, malformed URI, expired cert, auth failure, corrupt storage and permission denial.
- [ ] Parser fuzzing and secret-logging tests, resource/fd leak tests, stress/long-duration sessions and battery/performance baselines.
- [ ] Dependency/security advisories, SBOM, third-party license and attribution compliance; no unreviewed GPL/non-commercial copy.
- [ ] Build provenance, code signing, reproducible build checks, update/rollback, privacy policy and store checks.

## Recommended sequencing

Stage 0: CI + real Android tunnel must pass first; P0 security/lifecycle gate.
Stage 1: Xray reliability/import/subscription/QR/real locale; make daily customer use viable.
Stage 2: OpenVPN and WireGuard engines + proper .ovpn/.conf support; verify real server handshakes.
Stage 3: sing-box/Mihomo-specific modern protocols, Clash semantics and rule-based/Smart routing.
Stage 4: desktop and Apple native VPN services, TV UX and platform-specific lifecycle.
Stage 5: account/store/customer integrations and signed commercial release only after security/store approval.

Every checkbox requires link to source change, automatic tests, a genuine device or OS interoperability receipt when applicable, and an updated capability matrix. No UI-only checkmarks.
