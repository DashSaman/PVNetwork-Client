# Architecture

## Goal
PVNetwork must be able to add protocols without rebuilding the UI around a specific VPN engine.

## Layers
1. **UI** — Home, import, account, store, settings.
2. **ConnectionManager** — owns connection state and chooses adapters.
3. **ProtocolRegistry** — declares supported technical protocols and capabilities.
4. **ProtocolAdapter** — translates a normalized profile to an engine-specific request.
5. **Engine** — Xray/sing-box, OpenVPN, WireGuard, OpenConnect, IPsec, etc., selected license-by-license.
6. **Platform VPN layer** — Android VpnService / platform networking APIs.

## Rules
- No commercial product category is hard-coded into protocol code.
- Store categories and server pools are backend-driven.
- Imported third-party profiles are local by default.
- Infrastructure administrator credentials never enter the app.
- New protocol engines must be isolated behind adapters.

## Normalized profile concept
A future normalized profile contains: id, display name, protocol, endpoint metadata, raw/structured credentials, routing policy and engine requirements. Secrets are stored through platform secure storage.
