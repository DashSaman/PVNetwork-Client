# PVNetwork Core Selection

Research pass: 2026-08-14

Goal: maximum useful protocol coverage with the minimum reliable number of engines, while keeping commercial/store distribution and maintenance realistic.

## Decision C1 — Xray-core is the first modern-proxy adapter

Why:
- Mature VLESS/VMess/Trojan/Shadowsocks ecosystem.
- Upstream topics include REALITY, Vision, XHTTP and related modern transport/security capabilities.
- Current repository license metadata is MPL-2.0, which is substantially easier to isolate in a commercial product than copying a GPL application UI.
- Android references such as v2rayNG prove a mature mobile integration pattern exists.

PVNetwork implementation rule: wrap Xray behind `VpnCoreAdapter`; PVProfile remains engine-independent.

First acceptance target: VLESS + REALITY, VLESS TLS, VMess and Trojan import/normalize/generate/start/stop on Android, then desktop.

## Decision C2 — sing-box is a secondary capability engine, not the UI foundation

Why:
- Very broad modern-proxy coverage and strong multi-platform ecosystem.
- Needed for capabilities not covered adequately by the first adapter, especially after exact-version capability review.

Constraint:
- Upstream license is GPLv3-or-later with an additional naming/association condition. Bundling/linking implications must be reviewed for each platform and distribution channel.

PVNetwork will not copy Hiddify application code to obtain sing-box integration. Hiddify's current extended license includes a non-commercial condition without consent.

## Decision C3 — Mihomo is added only for real Clash semantics

Do not add Mihomo merely because it can run many protocols. Add it when PVNetwork implements Clash/Mihomo YAML behavior that is difficult or lossy to reproduce elsewhere, especially proxy groups, rule providers and selection policies.

## Decision C4 — OpenVPN uses OpenVPN 3 Core where technically appropriate

Upstream states OpenVPN 3 is used in production OpenVPN Connect clients across iOS, Android, Linux, Windows and macOS. Current upstream license offers AGPL-3.0 or MPL-2.0 licensing; exact component/version choice must be recorded before bundling.

PVNetwork target: `.ovpn` import including inline certificates, credential prompts/storage, UDP/TCP, IPv4/IPv6 where supported, DNS, routes, reconnect and cleanup.

`ics-openvpn` remains a valuable Android behavioral reference, but its README explicitly requires source publication for apps built on its GPL code; PVNetwork should not copy it casually.

## Decision C5 — WireGuard uses official/platform backends

The official Android repository exposes an embeddable tunnel library and opportunistically uses kernel WireGuard with userspace fallback. GitHub metadata currently reports Apache-2.0 for the Android project.

Other platforms should prefer official/platform-supported WireGuard mechanisms rather than inventing protocol code.

## Decision C6 — OpenConnect is the enterprise SSL-VPN adapter candidate

Official OpenConnect documentation currently lists support for Cisco AnyConnect-compatible VPNs and additional enterprise families including Pulse/Juniper, GlobalProtect, F5 and Fortinet. The core is LGPL-2.1. Exact platform integration and authentication capabilities must be tested before any PVNetwork green checkmark.

## Decision C7 — IPsec is platform-first

Use native Apple/Windows facilities where they fit the required profile. Evaluate strongSwan where a platform requires it. Avoid forcing a single IPsec implementation across all targets.

## Core Adapter contract

Every engine must implement equivalent application operations:

```text
probeCapabilities
validateProfile
normalizeProfile
generateConfig
start
stop
restart
healthCheck
getState
getStatistics
getLogs
collectDiagnostics
supportsFeature
getVersion
```

UI code may not call Xray, sing-box, OpenVPN, WireGuard or OpenConnect directly.

## Hosting model

- Android: signed in-app/native library or platform service, with Android `VpnService` ownership clearly separated from Flutter UI.
- Windows/Linux: prefer a separate core/helper process with authenticated local IPC where privilege separation is needed.
- macOS/iOS: use supported Network Extension architecture and signed embedded components; no unsupported runtime-code download.
- Android TV: reuse Android networking adapter, separate 10-foot UX.

## Reference evidence

- Xray-core upstream: https://github.com/XTLS/Xray-core
- sing-box upstream: https://github.com/SagerNet/sing-box
- FlClash platform/core separation: https://github.com/chen08209/FlClash/blob/main/.agents/architecture.md
- OpenVPN 3: https://github.com/OpenVPN/openvpn3
- WireGuard Android: https://github.com/WireGuard/wireguard-android
- OpenConnect: https://gitlab.com/openconnect/openconnect

This is an engineering selection document, not a support claim. `docs/PROTOCOL_MATRIX.md` remains the source of truth for verified PVNetwork capability.
