# UI Visual Audit — PVNetwork References

Visual research pass: 2026-08-14

Purpose: study hierarchy, navigation, profile import and connection workflows. This is not permission to copy any layout or brand one-to-one.

## Hiddify

Observed official/public screenshot pattern:
- mobile Home is extremely calm: top active subscription/profile card, quota/expiry information, large central connection control, explicit Connected/Disconnected state;
- adding a profile is visible from the top action rather than buried in a deep settings menu;
- Settings groups General and Advanced instead of mixing expert controls into Home;
- adaptive source confirms mobile navigation and wider NavigationRail behavior.

PVNetwork adoption:
- active PVNetwork service/profile summary near Home hero;
- one dominant gold Connect/Disconnect action;
- Advanced controls separated from normal use;
- do not copy Hiddify widgets/code because its current extended license is not suitable for unapproved commercial reuse.

Reference image: https://hiddify.com/assets/hiddify-next.png

## Karing

Upstream repository itself ships official screenshots:
- `README_assets/demo/home.png`
- `README_assets/demo/add_profile_link.png`
- `README_assets/demo/select_server.png`
- `README_assets/demo/routing_group.png`
- `README_assets/demo/connections.png`
- `README_assets/demo/setting.png`

Observed server-selection pattern:
- search first;
- Auto Select prominently separated from manual nodes;
- protocol label beside server;
- measured latency displayed at row level;
- Recommended and Recently Used sections reduce decision cost;
- subscription name/quota/expiry can coexist with the node list without requiring a separate technical profile editor.

Observed Add Profile pattern:
- profile link, clipboard, file, QR and custom/manual are separate explicit choices;
- users do not have to guess what a generic `+` does.

PVNetwork adoption:
- Add Connection sheet exposes Clipboard, File, Subscription URL, Manual and QR as separate actions;
- Server Picker will have Auto/Recommended/Recent/Favorites/Search;
- node row will show location/name, protocol, latency and source/profile;
- subscription usage/expiry stays visible but secondary.

Official upstream image source example:
https://github.com/KaringX/karing/blob/main/README_assets/demo/select_server.png

## Clash Verge Rev

Observed desktop pattern from project screenshots/docs:
- persistent left navigation is appropriate for wide screens;
- connection/subscription/rules/logs/testing are primary operational destinations;
- dashboard uses desktop width for multiple operational cards instead of centering a phone-sized card;
- TUN/system proxy/routing mode are explicit status controls.

PVNetwork adoption:
- NavigationRail/sidebar on Windows/Linux/macOS;
- Home becomes two-column on desktop;
- Connections Monitor, Routing, Logs and Diagnostics become desktop-first destinations after engines exist;
- no giant centered mobile power-button layout on desktop.

## FlClash

Visual/product lesson combined with upstream architecture:
- profile/node management and runtime status are separate concerns;
- desktop can expose more diagnostics while mobile stays compact;
- shared Flutter UI does not require identical platform integration underneath.

PVNetwork adoption:
- shared domain/profile model;
- platform-specific core/tunnel adapters;
- common connection state machine presented differently per form factor.

## v2rayNG / v2rayN

Observed product-level pattern:
- mature tools prioritize import/subscription/profile lists, routing and diagnostics over decorative Home screens;
- dense expert controls are valuable but can overwhelm general users.

PVNetwork adoption:
- preserve power under Advanced mode;
- normal flow remains Add → Select server/profile → Connect.

## Amnezia

Useful lesson:
- traditional VPNs need understandable profile/service setup and credential prompts;
- multi-protocol support needs a common connection model.

PVNetwork rejection:
- no copied Amnezia visual language, assets or branded wording;
- previous PVNetwork Amnezia-derived prototype is historical only.

## PVNetwork final visual direction

### Phone
Bottom destinations: Home / Connections / PVNetwork / Store / Settings.

Home hierarchy:
1. exact PRIVATE NETWORK artwork;
2. connection state;
3. selected service/profile and server;
4. large Connect button;
5. protocol + latency;
6. live traffic/IP after connection;
7. quick Add/Profile actions.

### Desktop
Sidebar plus two-column Home. Connections and diagnostics use full-width tables/cards. Server selector is searchable and latency-aware.

### TV
No stretched phone UI. Large focusable tiles, D-pad traversal, favorites/recent servers, QR/account pairing.

### Gold system
Gold is a primary-action/accent color, not a full-screen fill. Use near-black background, warm charcoal surfaces, ivory text and restrained gold glow. Green appears only for a verified healthy tunnel.

## Immediate build requirements derived from this audit

- official logo in launcher and in-app surfaces;
- explicit Add Connection choices;
- connection/profile list;
- server selector design before real multi-node subscription work;
- desktop sidebar, not centered phone card;
- Connect state comes from engine, never animation alone;
- profile source/quota/expiry model must have a place in Home/selector;
- Advanced settings stay out of the simple Home.
