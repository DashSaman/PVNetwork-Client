# PVNetwork Client

Official development repository for **PVNetwork VPN**.

## Current milestone: V0.1 Preview

The first CI milestone produces a real installable **Android 9+ ARM64 APK** for connection testing. It uses the latest pinned official Amnezia Android release (`5.0.0.5`) as the VPN runtime base, then applies PVNetwork display branding and a development signing key.

### Build output

GitHub Actions workflow: `PVNetwork Preview APK`

Artifact: `PVNetwork-Preview-APK`

APK: `PVNetwork-VPN-v0.1-preview-arm64.apk`

## Product direction

PVNetwork is being developed as both a public VPN client for user-supplied configs/subscriptions and a PVNetwork account/store client for managed services.

The commercial catalog is backend-driven. Category names, products, prices, server counts, protocol availability and audience rules must not be hard-coded into the client.

## Planned protocol architecture

`UI -> ConnectionManager -> ProtocolRegistry -> ProtocolAdapter -> Platform VPN layer`

Initial runtime coverage:
- VLESS / Reality / VMess through Xray
- OpenVPN UDP/TCP

Reserved adapters:
- WireGuard
- Hysteria2
- TUIC
- AnyTLS
- Trojan / Shadowsocks
- OpenConnect-compatible enterprise VPNs
- IKEv2/IPsec where supported by the platform

## Important V0.1 note

V0.1 is a **preview build**, not the final Play Store release. Upstream internal Android package and service class identifiers are intentionally preserved during the first installation/connection gate so the VPN engine is not broken. The final production package target is `com.pvnetwork.vpn`.

Production signing, Play Store AAB, backend authentication, store, ads and dynamic provisioning are separate release gates.

## License

The preview build modifies/redistributes Amnezia Client, which is GPL-3.0 licensed. Distribution must comply with the applicable GPL obligations and preserve relevant notices/source obligations.
