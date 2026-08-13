# Protocol Roadmap

Legend: `IMPORT` = detector/import schema exists, `ENGINE` = real tunnel engine integrated and tested.

| Protocol | V0.2 Import | Engine target |
|---|---:|---|
| VLESS | IMPORT | Xray/sing-box gate |
| VLESS + Reality | IMPORT | Xray/sing-box gate |
| VMess | IMPORT | Xray/sing-box gate |
| OpenVPN TCP/UDP | IMPORT | OpenVPN core gate |
| WireGuard | IMPORT | WireGuard gate |
| Trojan | IMPORT | Xray/sing-box gate |
| Shadowsocks | IMPORT | Xray/sing-box gate |
| Hysteria2 | IMPORT | compatible core gate |
| TUIC | IMPORT | compatible core gate |
| AnyTLS | IMPORT | compatible core gate |
| OpenConnect / AnyConnect | IMPORT | OpenConnect gate |
| IKEv2/IPsec | IMPORT | platform/IPsec gate |
| L2TP/IPsec | Planned | platform-specific review |
| SSTP | IMPORT | engine review |

## Acceptance rule
A protocol is never advertised as "supported" in release notes until connection, reconnect, DNS, IPv4/IPv6, kill/stop behavior and representative config tests pass on a real Android device.
