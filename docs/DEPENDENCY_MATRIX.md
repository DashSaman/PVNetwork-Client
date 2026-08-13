# PVNetwork Dependency Matrix

Research snapshot: 2026-08-14. Re-check exact versions/licenses before a production release.

| Dependency | Planned version | Purpose | Platforms | License/status |
|---|---|---|---|---|
| Flutter SDK | CI stable channel, pin before RC | UI/application shell | all | SDK terms; pin exact toolchain before release |
| flutter_secure_storage | 10.3.1 | encrypted storage for profiles/tokens/secrets | Android/iOS/Linux/macOS/Windows | BSD-3-Clause per current package metadata |
| file_picker | 11.0.2 | native config file import | Android/iOS/Linux/macOS/Windows | review exact package license in lockfile gate |
| mobile_scanner | 7.4.0 | QR scanning on supported camera platforms | Android/iOS/macOS | BSD-3-Clause per current package metadata |
| Xray-core | exact version TBD | first modern proxy engine adapter | target all practical platforms | MPL-2.0 repository metadata snapshot |
| OpenVPN 3 | exact version TBD | OpenVPN adapter | platform dependent | upstream offers AGPL-3.0 or MPL-2.0; select/document exact route |
| WireGuard official/platform components | exact version TBD | WireGuard adapter | platform dependent | Android repo metadata currently Apache-2.0; verify each platform component |
| OpenConnect | exact version TBD | enterprise SSL-VPN adapter | platform dependent | LGPL-2.1 core; verify platform wrapper |

Sensitive profile data must not be stored in ordinary preferences. Secure storage is the initial cross-platform storage mechanism; a metadata database can be added later with secrets referenced by secure-storage keys.
