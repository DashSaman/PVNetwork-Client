# Implementation Order

1. Exact PVNetwork brand assets.
2. Canonical PVProfile + secure local storage.
3. Responsive Home / Connections / PVNetwork / Store / Settings shell.
4. Add Connection via text/clipboard, file, subscription URL, manual form and QR where supported.
5. English + Persian/RTL.
6. Parser/profile tests.
7. First real Xray adapter: VLESS/REALITY, then VMess/Trojan.
8. Android VPN/TUN E2E.
9. Desktop core process/lifecycle: Windows, Linux, macOS.
10. OpenVPN `.ovpn` adapter.
11. WireGuard adapter.
12. Mihomo only for real Clash YAML/group semantics.
13. OpenConnect enterprise families.
14. Platform IPsec adapters.
15. Android TV remote-first UI and pairing.
16. Apple Network Extension/signing/compliance.
17. DNS/IPv6/reconnect/network-switch/route-cleanup reliability gates.
18. PVNetwork backend/store integration when real endpoint values are supplied.

No user-facing build is called a usable VPN client until at least one real adapter passes E2E.
