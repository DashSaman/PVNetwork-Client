# Xray Android Integration — PVNetwork

Research snapshot: 2026-08-14

## Evidence

Xray-core itself now documents Android TUN integration. Android `VpnService` creates the TUN interface and supplies a file descriptor; Xray's TUN inbound reads that descriptor through `xray.tun.fd` / `XRAY_TUN_FD`. Upstream explicitly documents `gomobile bind -target=android` for library integration.

Current Xray upstream release observed on GitHub: `v26.7.28` (2026-07-28, prerelease). Android arm64 release asset SHA-256 published by upstream: `a442892c175fa648fc56866ec872aac441c5a6b8946a1b60f0258ae16a7fb402`. PVNetwork will pin a source tag/commit and record generated-library checksums before a release.

Reference: `XTLS/Xray-core/proxy/tun/README.md` and official releases.

## Reference-client findings

v2rayNG currently carries `AndroidLibXrayLite` as a submodule and also carries `hev-socks5-tunnel`. Its README warns that an embedded core can become stale and documents rebuilding the mobile library. Its current core wrapper exposes lifecycle, delay/stat APIs, core version and an Android process-finder hook for UID-based routing.

PVNetwork does NOT copy v2rayNG application code. v2rayNG is GPL-3.0; its AndroidLibXrayLite wrapper is currently LGPL-3.0. The app is used only as an engineering reference.

## PVNetwork decision

PVNetwork will build a **small first-party gomobile wrapper** around Xray-core rather than copying another client wrapper.

The wrapper contract is intentionally narrow:

```text
initEnvironment(assetPath)
version()
validateConfig(json)
start(configJson, tunFd)
stop()
isRunning()
measureDelay(url)
stats()
```

The wrapper imports upstream Xray-core APIs and is kept in `core/xray-mobile/`. It contains no cryptography and no reimplementation of Xray protocols.

## Android ownership model

```text
Flutter UI
   │ Method/Event Channel
   ▼
PVNetwork Android Engine Plugin
   │
   ├── asks `VpnService.prepare()` permission
   ├── starts foreground `PVNetworkVpnService`
   ├── builds Android TUN
   ├── calls `protect()` / binds Xray upstream sockets correctly where required
   ├── passes TUN fd to first-party Xray gomobile wrapper
   └── streams state/stats/errors back to Flutter
          │
          ▼
      Xray TUN inbound
          │
          ▼
 VLESS / REALITY / VMess / Trojan outbound
```

## First TUN policy

Android `VpnService.Builder` initially owns routes and DNS rather than asking Xray to modify Android system routing. The first milestone uses a deterministic private TUN address, IPv4 default route and explicit DNS route. IPv6 is added only after the IPv6 leak test gate passes.

The Xray TUN inbound receives the fd and does not create a second Android VPN interface.

## Loop prevention

Full-tunnel routing can loop Xray's own uplink back into its TUN. The Android service must keep the core's upstream sockets outside the VPN path using supported Android VPN protection/socket-binding mechanisms. This is a hard release gate.

Tests:
- `xray_upstream_not_routed_back_into_tun`
- `vpn_disconnect_restores_default_routes`
- `vpn_service_restart_does_not_leave_stale_tun`

## DNS

Xray's own TUN documentation warns that DNS is separate network traffic and can leak destination information if routed incorrectly. Therefore PVNetwork does not call a tunnel “healthy” until DNS queries are verified through the intended policy.

Tests:
- `android_dns_no_system_leak_when_remote_dns_required`
- `android_dns_after_reconnect`
- `android_dns_after_wifi_cellular_switch`

## Connection state contract

Native layer emits only explicit states:

```text
Disconnected
Preparing
RequestingPermission
Connecting
EstablishingTunnel
Connected
Reconnecting
Disconnecting
Error
```

`Connected` may only be emitted after:
1. Android TUN established,
2. Xray core started without config error,
3. a health request successfully traversed the selected outbound.

## Initial protocol generator order

1. VLESS + REALITY + Vision
2. VLESS TLS / raw TCP
3. VMess
4. Trojan

Transport generators then expand to WebSocket, gRPC, XHTTP and other verified Xray capabilities.

## Android compatibility

The VpnService path targets the widest safe Android range allowed by the final dependencies. Current build remains `minSdk`-decision pending until the native wrapper and foreground-service behavior are compiled and tested. Google Play target API requirements must be rechecked immediately before production release.

## Known upstream risks converted to tests

- network switching can stall VPN clients → reconnect test
- local proxy exposure is unnecessary when Xray TUN inbound is available → PVNetwork first design is direct TUN inbound, no public SOCKS listener
- UID/process routing requires platform-specific process-owner lookup → add only after basic tunnel is stable
- upstream TUN/UDP regressions exist in historical releases → pin tested Xray version and add UDP/DNS/QUIC smoke coverage

## Licensing

Xray-core is MPL-2.0 at the current snapshot. PVNetwork will keep upstream notices and make required modified MPL-covered files available. First-party wrapper license and commercial application code remain separate. Exact release obligations are recorded in `THIRD_PARTY_LICENSES.md` before distribution.
