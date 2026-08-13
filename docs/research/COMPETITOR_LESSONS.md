# Competitor / Upstream Lessons

Research pass: 2026-08-14. This file records failures worth turning into PVNetwork tests. Findings are evidence inputs, not accusations against upstream projects.

## L-001 — DNS leak must be a release gate

Project: Hiddify App

Observed evidence: upstream issues include reported DNS-leak behavior on iOS and reports involving Android/Windows DNS resolution behavior.

PVNetwork lesson:
- DNS configuration and route configuration must be tested together.
- “Connected” is not sufficient evidence.
- Verification must include IPv4/IPv6 DNS queries, direct/remote DNS strategy, network changes and tunnel recreation.

PVNetwork acceptance tests to create:
1. `dns_no_system_leak_when_remote_dns_required`
2. `dns_ipv6_policy_matches_profile`
3. `dns_after_reconnect_uses_expected_route`
4. `dns_after_wifi_mobile_transition`

Reference: https://github.com/hiddify/hiddify-app/issues/1693 and related upstream DNS issues.

## L-002 — TUN must survive competing virtual adapters

Project: FlClash

Observed evidence: upstream Windows issue reports TUN failure after another application creates a Wintun virtual interface; system-proxy mode remains unaffected.

PVNetwork lesson:
- Never assume a single virtual adapter.
- Interface-selection logic needs explicit tests with adapters appearing/disappearing.
- A network-change event must not create a routing loop through PVNetwork’s own TUN.
- Route cleanup and recovery must not require reboot.

PVNetwork acceptance tests to create:
1. `windows_tun_survives_new_virtual_adapter`
2. `windows_no_tun_self_route_loop`
3. `windows_route_cleanup_after_core_restart`
4. `windows_recover_without_os_reboot`

Reference: https://github.com/chen08209/FlClash/issues/1957

## L-003 — Platform networking features need platform-specific semantics

Project: FlClash

Observed evidence: macOS transparent-gateway feature discussion highlights that TUN creation, routing and system IP forwarding are separate concerns.

PVNetwork lesson:
- Do not expose one “TUN works everywhere” abstraction without platform capability probes.
- Privileged helpers and system changes need explicit lifecycle/rollback behavior.
- Advanced gateway features are off by default and separately permissioned.

Reference: https://github.com/chen08209/FlClash/issues/2283

## L-004 — Do not ship stale embedded cores

Project: v2rayNG

Observed evidence: upstream README explicitly warns that the bundled AAR core may be outdated and documents rebuilding core libraries.

PVNetwork lesson:
- Pin core version and source commit.
- Record SHA256 of bundled core artifacts.
- CI must print core versions into build metadata.
- Security/release process must be able to update the core independently from UI refactors.

Reference: https://github.com/2dust/v2rayNG/blob/master/README.md

## L-005 — Mobile and desktop need different core hosting

Project: FlClash

Observed architecture: Android uses an in-process shared library through FFI; desktop uses a separate core process reached through a common controller interface.

PVNetwork lesson:
- UI must target `VpnCoreAdapter`, not a specific engine API.
- Desktop privileged networking can live in a helper/core process.
- Mobile adapters can use platform extensions/libraries while keeping the same application contract.

Reference: https://github.com/chen08209/FlClash/blob/main/.agents/architecture.md

## L-006 — Simple UI and expert controls must coexist

Projects: Hiddify, Karing, Clash Verge Rev, v2rayN/v2rayNG

Observed pattern:
- Hiddify emphasizes profile/subscription + one primary connection action.
- Karing explicitly separates Home, Add Profile, Server Selection, Routing Group, Connections and Settings.
- Clash Verge Rev uses a rich desktop sidebar and operational dashboard.
- v2rayN/v2rayNG expose mature expert configuration and profile management.

PVNetwork decision:
- **Simple mode**: Home, active service/profile, server, latency, protocol, Connect/Disconnect.
- **Primary navigation**: Home, Connections, PVNetwork, Store, Settings.
- **Advanced mode**: Routing, DNS, core, transport, logs, diagnostics, experimental controls.
- Desktop uses NavigationRail/sidebar; phone uses bottom navigation; TV gets its own D-pad-first shell.

## L-007 — License incompatibility is an engineering blocker

Hiddify’s current license adds explicit conditions including non-commercial use without consent. Karing and sing-box use GPL-family terms with additional naming/association language. FlClash, Clash Verge Rev, v2rayNG/v2rayN and Amnezia are GPL-family projects. Xray-core is MPL-2.0 at the current metadata snapshot.

PVNetwork lesson:
- We can study every project.
- We may not copy Hiddify application code into a commercial PVNetwork build without appropriate permission.
- Every bundled/link-time dependency needs exact-version license review before release.

References: upstream LICENSE files and GitHub repository metadata checked 2026-08-14.

## Regression-memory rule

When any of these tests fail during PVNetwork development, append the actual failure, attempted fix, evidence and the next *different* strategy to `docs/KNOWN_ISSUES.md` before retrying.
