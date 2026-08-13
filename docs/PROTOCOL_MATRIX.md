# PVNetwork Protocol Matrix

Last research pass: 2026-08-14

Status: ✅ E2E tested | 🟡 implemented/not fully verified | 🧪 experimental | 📋 planned | ❌ unsupported | ⚠️ legacy/security-sensitive.

**Verification rule:** an upstream engine supporting a protocol is not enough. PVNetwork marks a protocol ✅ only after import, validation, connection establishment, traffic, DNS/routing and disconnect cleanup are verified on the named platform.

| Family | Capability | Candidate adapter | Android | TV | Windows | macOS | Linux | iOS | PVNetwork E2E |
|---|---|---|---|---|---|---|---|---|---|
| Xray/V2Ray | VLESS | Xray-core / sing-box | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Xray/V2Ray | VLESS + REALITY / Vision | Xray-core / sing-box | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Xray/V2Ray | VMess | Xray-core / sing-box | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Proxy | Trojan | Xray-core / sing-box | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Proxy | Shadowsocks / 2022 variants | sing-box / Mihomo | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Proxy | SOCKS / HTTP proxy | sing-box / Xray-core | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Modern tunnel | Hysteria2 | sing-box / Mihomo | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Modern tunnel | TUIC | sing-box / Mihomo | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Modern tunnel | AnyTLS / ShadowTLS | current-core capability review | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Traditional VPN | OpenVPN UDP/TCP | OpenVPN adapter | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Traditional VPN | WireGuard | official/platform WireGuard adapter | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| IPsec | IKEv2/IPsec | native / strongSwan where appropriate | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Legacy VPN | IKEv1 / L2TP-IPsec | platform review | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ❌ |
| Traditional VPN | SSTP | platform/core review | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Traditional VPN | SoftEther | SoftEther compatibility review | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Enterprise SSL VPN | AnyConnect/ocserv-compatible | OpenConnect | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Enterprise SSL VPN | GlobalProtect / Fortinet / Pulse-Ivanti-Juniper / F5 / Array | OpenConnect capability review | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Clash/Mihomo | YAML profiles | Mihomo adapter | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |
| Clash/Mihomo | select/url-test/fallback/load-balance groups | Mihomo or PV policy layer | 📋 | 📋 | 📋 | 📋 | 📋 | 📋 | ❌ |

## Transport/security fields to preserve

PVProfile must preserve engine-relevant fields for TLS, REALITY, Vision, WebSocket, gRPC, HTTP/2, HTTP/3, QUIC, XHTTP, raw TCP/UDP, SNI, ALPN, fingerprints and multiplexing when the selected adapter supports them.

## Universal import target

Target inputs: `.ovpn`, `.conf`, JSON, YAML, QR, clipboard, subscription URL, Xray links, sing-box profiles, Clash/Mihomo profiles and WireGuard profiles. URI detection includes `vless://`, `vmess://`, `trojan://`, `ss://`, `hysteria2://`, `tuic://`, `wireguard://`, `socks://`, `http://` and `https://`.

Unsupported or unknown fields must be shown to the user; conversion must not silently discard security, transport, DNS or routing information.

## Current truth

The published `v0.2.0-alpha.1` is a cross-platform UI foundation. No protocol above is currently PVNetwork E2E-tested, so there are intentionally no green protocol checkmarks yet.
