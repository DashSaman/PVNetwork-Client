# PVNetwork Reference Client Matrix

Snapshot: 2026-08-14. These projects are references for UX/architecture only; reuse requires a separate license review.

| Project | Stars snapshot | Main role | Key PVNetwork lesson |
|---|---:|---|---|
| Clash Verge Rev | 137,612 | Desktop client, Tauri + Mihomo | Persistent desktop sidebar; dashboard for traffic, current node, system/TUN controls, rules, logs and tests |
| v2rayN | 113,762 | Desktop multi-core client | Mature profile/subscription management, tray behavior and diagnostics |
| v2rayNG | 61,022 | Android Xray/V2Ray client | Mature Android profile/import and VPN lifecycle reference |
| FlClash | 48,460 | Flutter cross-platform client | Android shared-library core; desktop separate core process; common controller interface; database-backed profiles |
| Xray-core | 41,013 | Networking core | Candidate modern protocol adapter; MPL-2.0 snapshot |
| sing-box | 36,979 | Networking core | Broad modern protocol candidate; GPLv3-or-later plus upstream naming condition |
| Hiddify App | 32,051 | Flutter cross-platform client | Excellent simple home/profile experience and adaptive mobile/desktop navigation; custom extended license includes non-commercial restriction, so research only for PVNetwork |
| Karing | 14,242 | Flutter cross-platform client | Official demo set covers Home, Add Profile Link, Select Server, Routing Group, Connections and Settings |
| Amnezia Client | 14,434 | Multi-protocol mobile/desktop client | Useful traditional-VPN UX/platform lessons; never copy its branding/UI into PVNetwork |
| WireGuard Android | verify at integration | Android reference | WireGuard profile/backend design |
| OpenVPN for Android | verify at integration | Android reference | `.ovpn`, credentials/certificates and VpnService integration |
| strongSwan | verify at integration | IPsec reference | IKE/IPsec architecture and platform constraints |
| OpenConnect | verify at integration | Enterprise VPN core | Enterprise adapter candidate; verify each supported server family per platform |
| Happ | closed/product reference | UX reference | Product/UX study from official materials only; do not assume or copy internal implementation |

## UI observations

**Hiddify:** official screenshots prioritize active profile/subscription information and a large connection state/control. Current source uses a bottom `NavigationBar` on mobile and `NavigationRail` on wider layouts; desktop can expose Profiles, Logs and About without crowding mobile.

**Karing:** its upstream repo includes screenshots named `home`, `add_profile_link`, `select_server`, `routing_group`, `connections` and `setting`. PVNetwork therefore treats Add Profile, Server Selection and Connections as primary flows, not optional future screens.

**Clash Verge Rev:** desktop screenshots show Home, Proxy, Subscription, Connections, Rules, Logs, Tests and Settings in a persistent sidebar. Operational toggles and traffic/IP information are visible on the dashboard.

**FlClash:** upstream architecture documents an Android in-process core library and a desktop core process communicating through a common controller abstraction. It also separates platform managers for VPN, connectivity, tray/window and core lifecycle.

**v2rayNG / v2rayN:** valuable mature references for dense expert capabilities. PVNetwork should preserve their power while separating Simple and Advanced modes.

## Conclusion for PVNetwork

`v0.2.0-alpha.1` is below this benchmark: no connection/profile manager, no import flow, no server selector, no PVNetwork account/store and incorrect generated Flutter launcher branding. It remains build-pipeline evidence only and must be replaced.

Sources: upstream GitHub repositories for the projects above plus official project screenshots/documentation. Metadata/licenses must be rechecked at the exact dependency version before reuse.
