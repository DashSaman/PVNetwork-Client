# Security Contract

- Do not commit production API secrets, VPN credentials, signing keys or panel administrator passwords.
- The client talks to a PVNetwork Gateway API, never directly with administrator credentials for provisioning panels.
- HTTPS is mandatory for PVNetwork cloud APIs.
- Use short-lived access tokens plus refresh tokens.
- Imported third-party profiles remain local by default.
- Production secrets must use Android Keystore-backed storage where applicable.
- Release signing keys stay outside the repository and are provided to CI through protected secrets.
- Protocol engines are reviewed for license, update policy and security before integration.
- Advertising, when added, is UI-only and must never be injected into VPN traffic.
