# Changelog

## 0.3.0-dev — First real tunnel engine (in progress)
- `PVProfile` v2 schema: `transport`, `security`, `dnsPolicy`, `routingPolicy`, `engineRequirements`, `secretRefs`; v1 documents keep loading unchanged.
- `ProfileDetector` populates v2 fields for all URI schemes and VMess JSON; every profile now declares its required engine honestly (xray / sing-box / wireguard / openvpn / mihomo).
- `SecretStore` abstraction (`flutter_secure_storage` backend + in-memory test backend) with `$ref{field}` indirection; profile secrets survive export/share without leaking.
- `XrayConfigBuilder` completed: Shadowsocks (SIP002 + legacy, plugins refused explicitly), SOCKS, HTTP(S) outbounds; DNS strategies (secure/system/cloudflare/off) with port-53 hijack; routing with always-direct private CIDRs and opt-in `bypassIR`; `stats`/`policy` blocks for live traffic counters.
- `pvxray` Go wrapper: `InitEnvironment`, `QueryUplink`, `QueryDownlink`, `ResetStats`, `MeasureDelay` (through the running tunnel), `MeasureDirectDelay`; covered by Go tests (`go test ./...` runs in CI).
- `XrayMobileBinding` MethodChannel contract + `XrayAdapter` implementing `VpnCoreAdapter` (pure Dart, unit-testable).
- Android host patches: reflective `PvxrayBridge`, `PvxrayPlugin` (start resolves only after the TUN is established), `PVVpnService` foreground service with permission flow; patches applied by `scripts/setup_host_projects.sh` locally and in CI.
- `universal-release.yml` Android job now fetches the latest `pvnetwork-xray-android-aar` artifact and wires it into the build host automatically.
- Controller: real connect/disconnect/reconnect lifecycle, engine registry (`EngineRegistry`), live stats polling, honest error surfacing; profiles requiring missing engines are refused, never silently mis-routed.
- HomePage: live connection state, error banner, latency/traffic/engine rows; "Connect" works when the native core is available.

## 0.2.0 — Dedicated foundation
- New dedicated Android application identity: `com.pvnetwork.vpn`.
- Dedicated PVNetwork splash, vector icon and home UI.
- Public configuration import/detection flow.
- Protocol registry for a multi-engine architecture.
- Initial localization: EN, FA, AR, TR, RU, DE, FR, ES, ZH-CN.
- RTL enabled.
- Architecture, security, backend and protocol-roadmap documentation.
- New source-build Android CI pipeline.
