# PVNetwork Third-Party License Gate

No dependency is approved for release solely because it is open source.

Current research decisions:
- Hiddify application code: **research only** for commercial PVNetwork unless explicit permission is obtained; current extended license contains a non-commercial condition.
- Xray-core: candidate first core; repository metadata currently MPL-2.0. Exact release/license files must be archived at integration.
- sing-box: candidate secondary core; current license text is GPLv3-or-later with an additional naming/association condition. Integration form must be reviewed before bundling.
- OpenVPN 3: upstream currently offers AGPL-3.0 or MPL-2.0. PVNetwork integration must explicitly record the chosen licensing path.
- WireGuard: use official/platform components; verify license per bundled component.
- OpenConnect: LGPL-2.1 core; verify wrappers and distribution obligations.
- GPL client applications such as FlClash, Clash Verge Rev, v2rayN/v2rayNG and Amnezia are engineering references unless PVNetwork intentionally adopts compatible GPL reuse with all corresponding obligations.

Every release must include exact dependency versions, source locations, modifications, attribution/source obligations and store compatibility evidence.
