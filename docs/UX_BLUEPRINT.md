# PVNetwork UX Blueprint

Research pass: 2026-08-14

PVNetwork is not a reskin of Hiddify, Amnezia, Clash Verge, Karing or any other client. It combines proven interaction patterns with its own black/gold identity and exact supplied PRIVATE NETWORK logo.

## Design principles

1. **Connection truth first.** Never animate or label Connected unless a core adapter reports a real established tunnel and health check.
2. **Simple by default.** Normal users see service/profile, server, latency, protocol and one primary Connect/Disconnect action.
3. **Power without clutter.** Expert functions live under Advanced: routing, DNS, transport, core, logs and diagnostics.
4. **Import is a primary flow.** A public client must let a guest add a connection without an account.
5. **PVNetwork commercial layer is optional.** Login/store/services coexist with guest/manual profiles.
6. **Responsive, not stretched.** Phone, desktop and TV use different navigation shells while sharing domain logic.

## Phone navigation

Bottom navigation:

1. Home
2. Connections
3. PVNetwork
4. Store
5. Settings

### Home

Header: official PVNetwork logo + account/avatar action.

Hero connection panel:
- connection state chip
- current profile/service name
- location/server
- protocol
- latency
- large gold Connect/Disconnect control
- elapsed time when connected

Live compact metrics after connection:
- download/upload rate
- session totals
- public IP (optional reveal)

Quick server selector opens a bottom sheet rather than navigating away.

### Connections

Tabs/filters:
- All
- Manual
- Subscriptions
- Favorites
- PVNetwork

Profile cards show:
- name
- country/location if known
- protocol
- latency
- source badge
- favorite
- last-used status

Primary `+` opens Add Connection.

### Add Connection

Large, explicit options:
- Paste from Clipboard
- Scan QR
- Import File
- Subscription URL
- Manual Configuration
- PVNetwork Account Sync

Detection pipeline shown only when needed:
Input → Detected format → Validation → Preview → Save.

Lossy conversion produces a visible warning listing unsupported fields; Save cannot silently discard critical fields.

### PVNetwork

Guest state:
- Sign in
- Create account
- Pair device
- explanation that login is optional for manual profiles

Signed-in state:
- account summary
- devices
- active services
- traffic remaining
- expiration
- Sync
- support

### Store

Backend-driven categories/products. No protocol/pricing/category hardcoding in the app.

Product card:
- product name
- short use-case
- location count / server-pool summary
- supported verified connection options
- traffic/duration
- price resolved by backend audience

### Settings

Simple section:
- Language
- Theme: System/Light/Dark
- Auto-connect
- Kill switch (only where truly implemented)
- Notifications

Advanced section:
- Routing mode
- DNS
- Split tunnel/per-app
- Core selection where meaningful
- MTU
- Logs
- Diagnostics
- Experimental
- About/licenses

## Desktop navigation

Persistent left sidebar, influenced by the information density that works well in Clash Verge Rev but with PVNetwork's own layout:

- Home
- Connections
- Subscriptions
- PVNetwork
- Store
- Routing
- Connections Monitor
- Logs
- Settings

Bottom of sidebar:
- current upload/download
- core state
- app version

Desktop Home uses a two-column dashboard:
- left: connection/status + server selection
- right: active subscription/service + live traffic/IP/latency

No giant empty mobile card centered in a desktop window.

## Android TV / Google TV

D-pad-first navigation:
- Connect / Disconnect
- Current Server
- Protocol
- Latency
- Favorites
- Recent
- PVNetwork service status
- QR Pair / QR Import
- Settings

No touch dependency. Advanced text configuration is hidden by default; use account sync, QR or short pairing code.

## Connection states

Explicit UI states:

`Disconnected → Preparing → RequestingPermission → Connecting → Authenticating → EstablishingTunnel → Connected → Reconnecting → Disconnecting → Error`

Each state has:
- title
- compact explanation
- cancel/retry action where applicable
- diagnostic ID on error

## Visual system

PVNetwork master style:
- background: near-black, not pure flat black everywhere
- elevated surfaces: warm charcoal
- primary gold: controlled, used for primary action/highlight rather than flooding the screen
- secondary gold/amber for hover/focus/glow
- white/ivory typography
- muted warm gray secondary text
- green only for verified healthy connection state
- red only for errors/danger actions

Avoid excessive neon, rainbow gradients and generic shield icons.

The supplied PRIVATE NETWORK logo is the primary brand asset. Decorative glow may be applied around its container, but the asset itself must not be recolored, distorted or redrawn.

## Motion

- 180–240ms surface/navigation transitions
- connection ring may animate only while a real connection operation is active
- Connected state becomes calm/static
- respect reduced-motion accessibility settings

## Persian / RTL

Persian is first-class. Navigation direction mirrors where appropriate, while IP addresses, ports, URLs, hashes, protocol identifiers and paths remain LTR/readable. Mixed examples like `سرور آلمان — VLESS — 192.0.2.1:443 — Reality` must be tested.

## Release UI gate

A build must not be offered as a usable VPN client unless at minimum these are functional:
- official launcher/app logo
- Home
- Connections
- Add Connection
- real local profile persistence
- at least one real import path
- real connection state from at least one working core adapter
- Settings
- English + Persian/RTL core UI
- error/diagnostic path

Account and Store can remain separately labeled beta until a real backend endpoint is configured; placeholder buttons must not pretend to complete purchases or authentication.
