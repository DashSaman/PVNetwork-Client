# PVNetwork Universal VPN Client

**PVNetwork VPN** is being built as a dedicated, public, multi-language and multi-protocol VPN client.

## Current milestone — V0.2 Dedicated Foundation

- Independent Android application source
- Android package: `com.pvnetwork.vpn`
- Dedicated PVNetwork splash, icon and UI
- Multi-language resources: English, Persian, Arabic, Turkish, Russian, German, French, Spanish, Simplified Chinese
- RTL support
- Generic configuration import/detection layer
- Protocol registry designed for multiple engines
- GitHub Actions Android build

## Current protocol status

V0.2 can identify/import common forms of VLESS, Reality, VMess, OpenVPN, WireGuard, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, OpenConnect/AnyConnect, IKEv2 and SSTP.

**Import support is not the same as tunnel-engine support.** Native connection engines are integrated in later gates and tracked in `docs/PROTOCOL_ROADMAP.md`.

## Product principle

The client is public first: users can bring their own configuration. PVNetwork commercial services are an optional layer, not a requirement to use the client.

`UI -> ConnectionManager -> ProtocolRegistry -> ProtocolAdapter -> Engine -> Platform VPN API`

## Build

GitHub Actions workflow: `PVNetwork Android CI`

Expected artifact: `PVNetwork-VPN-v0.2-dedicated-debug.apk`

See `docs/BUILD.md`.

## Documentation

- `docs/ARCHITECTURE.md`
- `docs/ARCHITECTURE_FA.md`
- `docs/PROTOCOL_ROADMAP.md`
- `docs/LOCALIZATION.md`
- `docs/SECURITY.md`
- `docs/BACKEND_CONTRACT.md`
- `docs/ROADMAP.md`
- `CHANGELOG.md`
