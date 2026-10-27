# PVNetwork Universal — Comprehensive Master Feature Catalog

Date: 2026-10-27. Source: independent 2026 competitor and PVNetwork audit. Goal: consolidate features of Karing, Hiddify, v2rayNG/v2rayN, FlClash, Clash Verge Rev, NekoBox/NekoRay, Shadowrocket, Stash, V2Box/Happ, OpenVPN Connect, WireGuard, AmneziaVPN, OpenConnect and PVNetwork customer integrations into one product.

IMPORTANT: This is a PRODUCT REQUIREMENTS backlog, not a claim of implemented features. All boxes default unchecked. P0 means release-blocker foundation, P1 means full consumer parity, P2 means advanced or regulated/platform-limited. Features may only be marked done after evidence of implementation and proper tests. Proposals are not claims that any named competitor has all features. Feature availability depends on protocol/core version, platform APIs, and app store rules. Do not copy third-party protected code, assets, or trade dress without appropriate license.

## Section overview

| ID | Domain | Priority | Count |
|---|---|---|---:|
| CORE | معماری و قابلیت‌های پایه | P0 | 12 |
| XRAY | پروتکل‌های Xray/V2Ray | P0 | 14 |
| TRANSPORT | لایه‌های حمل و TLS | P1 | 16 |
| MODERN | پروتکل‌های جدید و استتار | P1 | 19 |
| VPN | VPNهای کلاسیک | P1 | 22 |
| IMPORT | ورودی کانفیگ‌ها | P0 | 25 |
| SUB | سابسکریپشن و منابع | P0 | 23 |
| PROFILE | مدیریت پروفایل | P1 | 19 |
| TEST | تست و انتخاب هوشمند نود | P1 | 20 |
| ROUTE | مسیریابی و Rule Engine | P1 | 28 |
| DNS | DNS و امنیت Resolver | P1 | 22 |
| LIFECYCLE | پایداری و مدیریت اتصال | P0 | 23 |
| MONITOR | آمار و لاگ و تشخیص | P1 | 23 |
| DESKTOP | ویندوز و لینوکس و مک | P1 | 23 |
| ANDROID | اندروید | P1 | 20 |
| TV | Android TV و Google TV | P1 | 16 |
| APPLE | iPhone/iPad/macOS/tvOS | P1 | 18 |
| UI | رابط کاربری و شخصی‌سازی | P1 | 27 |
| SYNC | بکاپ و همگام‌سازی | P1 | 18 |
| ADV | امکانات بسیار پیشرفته Stash/Shadowrocket | P2 | 19 |
| ACCOUNT | حساب و فروشگاه PVNetwork | P1 | 21 |
| OPS | سازگاری پنل‌ها و زیرساخت | P2 | 18 |
| SELFHOST | راه‌اندازی سرور شخصی | P2 | 15 |
| ENTERPRISE | اتصال سازمانی | P2 | 15 |
| RELEASE | آزمون امنیت و انتشار | P0 | 27 |

## Full feature checklist

### CORE — معماری و قابلیت‌های پایه

Priority: P0. Platforms: ALL.

- [ ] PVF-001 [P0] یک اپ با چند موتور پشت API مشترک
- [ ] PVF-002 [P0] تعویض موتور بدون تغییر رابط کاربری
- [ ] PVF-003 [P0] قابلیت‌یابی واقعی OS/engine/version
- [ ] PVF-004 [P0] حالت ساده و پیشرفته
- [ ] PVF-005 [P0] کنترل معتبر Connect/Stop/Cancel/Restart
- [ ] PVF-006 [P0] State machine و timeout و race-safe switching
- [ ] PVF-007 [P0] تفکیک profile اصلی از config runtime
- [ ] PVF-008 [P0] مهاجرت نسخه‌های دیتابیس بدون فقدان داده
- [ ] PVF-009 [P0] Guest mode بدون حساب اجباری
- [ ] PVF-010 [P0] نمایش خطای قابل‌فهم و شناسه تشخیصی
- [ ] PVF-011 [P0] عدم نمایش Connected قبل از اثبات data path
- [ ] PVF-012 [P0] API مستقل برای core adapter و UI

### XRAY — پروتکل‌های Xray/V2Ray

Priority: P0. Platforms: ENGINE.

- [ ] PVF-013 [P0] VLESS
- [ ] PVF-014 [P0] VLESS REALITY و Vision
- [ ] PVF-015 [P0] VMess legacy و AEAD
- [ ] PVF-016 [P0] Trojan و TLS
- [ ] PVF-017 [P0] Shadowsocks AEAD
- [ ] PVF-018 [P0] Shadowsocks 2022 در موتور سازگار
- [ ] PVF-019 [P0] SOCKS5
- [ ] PVF-020 [P0] HTTP/HTTPS proxy
- [ ] PVF-021 [P0] پروفایل‌های V2Ray V2Fly Xray JSON
- [ ] PVF-022 [P0] VMess encoded JSON
- [ ] PVF-023 [P0] VLESS share URI
- [ ] PVF-024 [P0] Xray full configuration و multi-outbound
- [ ] PVF-025 [P0] uTLS و fingerprint
- [ ] PVF-026 [P0] XTLS flow و security parameters

### TRANSPORT — لایه‌های حمل و TLS

Priority: P1. Platforms: ENGINE.

- [ ] PVF-027 [P1] TCP RAW
- [ ] PVF-028 [P1] WebSocket host path header
- [ ] PVF-029 [P1] gRPC serviceName/authority
- [ ] PVF-030 [P1] HTTPUpgrade
- [ ] PVF-031 [P1] XHTTP یا SplitHTTP
- [ ] PVF-032 [P1] HTTP/2
- [ ] PVF-033 [P1] HTTP/3 در موتور معتبر
- [ ] PVF-034 [P1] mKCP
- [ ] PVF-035 [P1] QUIC transport در موتور معتبر
- [ ] PVF-036 [P1] TLS SNI ALPN
- [ ] PVF-037 [P1] REALITY public key short ID fingerprint
- [ ] PVF-038 [P1] Certificate verification و fingerprint pinning
- [ ] PVF-039 [P1] Multiplexing Mux
- [ ] PVF-040 [P1] TCP و UDP transport options
- [ ] PVF-041 [P1] IPv6 endpoint/SNI/IDN support
- [ ] PVF-042 [P1] Network congestion and keepalive controls

### MODERN — پروتکل‌های جدید و استتار

Priority: P1. Platforms: ENGINE.

- [ ] PVF-043 [P1] Hysteria1
- [ ] PVF-044 [P1] Hysteria2
- [ ] PVF-045 [P1] TUIC
- [ ] PVF-046 [P1] AnyTLS
- [ ] PVF-047 [P1] ShadowTLS
- [ ] PVF-048 [P1] NaiveProxy و naive+https
- [ ] PVF-049 [P1] Snell
- [ ] PVF-050 [P1] Mieru
- [ ] PVF-051 [P1] Juicity
- [ ] PVF-052 [P1] TrustTunnel با موتور معتبر
- [ ] PVF-053 [P1] ShadowsocksR نیازمند بررسی legacy
- [ ] PVF-054 [P1] AmneziaWG
- [ ] PVF-055 [P1] SSH dynamic proxy
- [ ] PVF-056 [P1] Tor/SOCKS bridge اختیاری
- [ ] PVF-057 [P1] OpenVPN over Cloak
- [ ] PVF-058 [P1] OpenVPN over Shadowsocks
- [ ] PVF-059 [P1] Shadowsocks plugins obfs/v2ray-plugin
- [ ] PVF-060 [P1] چندهاپ یا chain outbound
- [ ] PVF-061 [P1] امکان افزودن موتور جدید با registry امن

### VPN — VPNهای کلاسیک

Priority: P1. Platforms: OS.

- [ ] PVF-062 [P1] OpenVPN TCP
- [ ] PVF-063 [P1] OpenVPN UDP
- [ ] PVF-064 [P1] OpenVPN3 core در مسیر قانونی مناسب
- [ ] PVF-065 [P1] OVPN inline certificates
- [ ] PVF-066 [P1] OVPN external certificates and key files
- [ ] PVF-067 [P1] OpenVPN tls-auth/tls-crypt
- [ ] PVF-068 [P1] OpenVPN client credentials/password prompts
- [ ] PVF-069 [P1] OpenVPN reconnect route and DNS push
- [ ] PVF-070 [P1] WireGuard .conf
- [ ] PVF-071 [P1] WireGuard multi-peer
- [ ] PVF-072 [P1] WireGuard AllowedIPs routing
- [ ] PVF-073 [P1] WireGuard pre-shared key and keepalive
- [ ] PVF-074 [P1] WireGuard MTU/roaming
- [ ] PVF-075 [P1] AmneziaWG .conf and obfuscation fields
- [ ] PVF-076 [P1] IKEv2/IPsec
- [ ] PVF-077 [P1] IKEv1/L2TP-IPsec legacy optional
- [ ] PVF-078 [P1] SSTP adapter
- [ ] PVF-079 [P1] SoftEther protocol adapter
- [ ] PVF-080 [P1] OpenConnect AnyConnect/ocserv
- [ ] PVF-081 [P1] OpenConnect GlobalProtect
- [ ] PVF-082 [P1] OpenConnect Pulse/Juniper
- [ ] PVF-083 [P1] OpenConnect Fortinet/F5/Array

### IMPORT — ورودی کانفیگ‌ها

Priority: P0. Platforms: ALL.

- [ ] PVF-084 [P0] Import clipboard
- [ ] PVF-085 [P0] QR camera scan
- [ ] PVF-086 [P0] QR from gallery
- [ ] PVF-087 [P0] QR export and share
- [ ] PVF-088 [P0] Import .ovpn
- [ ] PVF-089 [P0] Import .conf
- [ ] PVF-090 [P0] Import JSON/YAML/TXT/ZIP
- [ ] PVF-091 [P0] Share-sheet/intent/deep-link
- [ ] PVF-092 [P0] VLESS VMess Trojan SS schemes
- [ ] PVF-093 [P0] HY2 TUIC Naive URI
- [ ] PVF-094 [P0] Multi-line/bundle import
- [ ] PVF-095 [P0] Base64 subscription content import
- [ ] PVF-096 [P0] Full Xray config normalization
- [ ] PVF-097 [P0] Full sing-box config normalization
- [ ] PVF-098 [P0] Full Clash/Mihomo YAML
- [ ] PVF-099 [P0] Surge/Surfboard/Stash syntax if documented
- [ ] PVF-100 [P0] Manual profile editor
- [ ] PVF-101 [P0] Raw config editor with validation
- [ ] PVF-102 [P0] Lossy conversion preview
- [ ] PVF-103 [P0] Redact secrets during import/export
- [ ] PVF-104 [P0] Duplicate profile detection
- [ ] PVF-105 [P0] Import rollback on failure
- [ ] PVF-106 [P0] Custom protocol link parser with version gates
- [ ] PVF-107 [P0] IPv6 literal and unicode handling
- [ ] PVF-108 [P0] Multiple formats per remote URL

### SUB — سابسکریپشن و منابع

Priority: P0. Platforms: ALL.

- [ ] PVF-109 [P0] Multiple subscriptions
- [ ] PVF-110 [P0] Auto refresh intervals
- [ ] PVF-111 [P0] Refresh all and single
- [ ] PVF-112 [P0] ETag/If-Modified-Since conditional download
- [ ] PVF-113 [P0] Last sync time and error
- [ ] PVF-114 [P0] Used/remaining quota
- [ ] PVF-115 [P0] Expiry date and warning
- [ ] PVF-116 [P0] User-agent format negotiation
- [ ] PVF-117 [P0] Headers and auth token in SecretStore
- [ ] PVF-118 [P0] Allow proxied or direct fetch
- [ ] PVF-119 [P0] TLS verification and redirect policy
- [ ] PVF-120 [P0] Parse preview with node diffs
- [ ] PVF-121 [P0] Preserve local favorites after refresh
- [ ] PVF-122 [P0] Atomic update and rollback
- [ ] PVF-123 [P0] Conflict/duplicate merge options
- [ ] PVF-124 [P0] Failed refresh does not drop usable servers
- [ ] PVF-125 [P0] Import trial and persistent link separately
- [ ] PVF-126 [P0] Auto-test after update
- [ ] PVF-127 [P0] Format override per provider
- [ ] PVF-128 [P0] Subscription history and versions
- [ ] PVF-129 [P0] Auto update on allowed Wi-Fi/battery
- [ ] PVF-130 [P0] Secure URL share without credentials
- [ ] PVF-131 [P0] Provider grouping, tag, color, icon

### PROFILE — مدیریت پروفایل

Priority: P1. Platforms: ALL.

- [ ] PVF-132 [P1] Server list grouped by source
- [ ] PVF-133 [P1] Folder/collection management
- [ ] PVF-134 [P1] Favorite
- [ ] PVF-135 [P1] Recent/last used
- [ ] PVF-136 [P1] Rename
- [ ] PVF-137 [P1] Duplicate
- [ ] PVF-138 [P1] Edit
- [ ] PVF-139 [P1] Delete with undo
- [ ] PVF-140 [P1] Search
- [ ] PVF-141 [P1] Filter by protocol
- [ ] PVF-142 [P1] Filter by location
- [ ] PVF-143 [P1] Sort name/latency/source
- [ ] PVF-144 [P1] Bulk select and remove
- [ ] PVF-145 [P1] Copy/export config
- [ ] PVF-146 [P1] Display unsupported capabilities
- [ ] PVF-147 [P1] Profile-specific DNS/routing overrides
- [ ] PVF-148 [P1] Cross-subscription node deduplication
- [ ] PVF-149 [P1] Dynamic group selection
- [ ] PVF-150 [P1] Connection history per node

### TEST — تست و انتخاب هوشمند نود

Priority: P1. Platforms: ALL.

- [ ] PVF-151 [P1] HTTP probe through tunnel
- [ ] PVF-152 [P1] Direct vs proxy delay
- [ ] PVF-153 [P1] Batch latency test
- [ ] PVF-154 [P1] Custom probe URL
- [ ] PVF-155 [P1] Probe timeout and retries
- [ ] PVF-156 [P1] TCP ping latency where applicable
- [ ] PVF-157 [P1] TLS handshake timing
- [ ] PVF-158 [P1] Download/upload throughput test with bandwidth cap
- [ ] PVF-159 [P1] Real outgoing IP and ASN
- [ ] PVF-160 [P1] Node health score based on evidence
- [ ] PVF-161 [P1] URL-test automatic best
- [ ] PVF-162 [P1] Fallback group
- [ ] PVF-163 [P1] Load-balance group
- [ ] PVF-164 [P1] Manual select group
- [ ] PVF-165 [P1] Priority/weight selection
- [ ] PVF-166 [P1] Latency history and last measured
- [ ] PVF-167 [P1] Exclude failed nodes
- [ ] PVF-168 [P1] Auto failover while maintaining session semantics
- [ ] PVF-169 [P1] Per-profile compatibility verification
- [ ] PVF-170 [P1] Distinguish ICMP ping from HTTP latency

### ROUTE — مسیریابی و Rule Engine

Priority: P1. Platforms: ENGINE+OS.

- [ ] PVF-171 [P1] Global proxy
- [ ] PVF-172 [P1] Direct
- [ ] PVF-173 [P1] Rule-based mode
- [ ] PVF-174 [P1] Smart mode
- [ ] PVF-175 [P1] Private LAN bypass
- [ ] PVF-176 [P1] Domain exact/suffix/keyword/regex
- [ ] PVF-177 [P1] IP CIDR v4/v6
- [ ] PVF-178 [P1] GeoIP country
- [ ] PVF-179 [P1] GeoSite categories
- [ ] PVF-180 [P1] ASN routing where supported
- [ ] PVF-181 [P1] Port-based routing
- [ ] PVF-182 [P1] Protocol-based routing
- [ ] PVF-183 [P1] App/process-based routing when supported
- [ ] PVF-184 [P1] SSID-aware routing where supported
- [ ] PVF-185 [P1] Custom rules ordering
- [ ] PVF-186 [P1] Ruleset remote provider update
- [ ] PVF-187 [P1] Ruleset local file import
- [ ] PVF-188 [P1] Mihomo proxy-groups
- [ ] PVF-189 [P1] Selector/url-test/fallback/load-balance
- [ ] PVF-190 [P1] Rule editor graphical
- [ ] PVF-191 [P1] Config merge and override
- [ ] PVF-192 [P1] Safe script rules
- [ ] PVF-193 [P1] Reject/block mode
- [ ] PVF-194 [P1] IP/domain whitelist and blacklist
- [ ] PVF-195 [P1] Geo rules for Iran and other regions
- [ ] PVF-196 [P1] Routing decision inspector
- [ ] PVF-197 [P1] Custom inbound/mixed ports when authorized
- [ ] PVF-198 [P1] IPv6 and UDP routing exceptions

### DNS — DNS و امنیت Resolver

Priority: P1. Platforms: ENGINE+OS.

- [ ] PVF-199 [P1] System DNS
- [ ] PVF-200 [P1] Custom IPv4/IPv6 DNS
- [ ] PVF-201 [P1] DoH
- [ ] PVF-202 [P1] DoT
- [ ] PVF-203 [P1] DoQ if engine supports
- [ ] PVF-204 [P1] DoT/DoH through proxy
- [ ] PVF-205 [P1] Fallback and bootstrap DNS
- [ ] PVF-206 [P1] Split DNS
- [ ] PVF-207 [P1] FakeIP
- [ ] PVF-208 [P1] FakeIP exclusion
- [ ] PVF-209 [P1] Hosts mapping
- [ ] PVF-210 [P1] DNS cache clear
- [ ] PVF-211 [P1] DNS routing per rule
- [ ] PVF-212 [P1] DNS query log
- [ ] PVF-213 [P1] Domain sniffing if allowed
- [ ] PVF-214 [P1] Prefer IPv4/IPv6 policies
- [ ] PVF-215 [P1] Remote DNS without system leaks
- [ ] PVF-216 [P1] IPv6 leak tests
- [ ] PVF-217 [P1] DNS continuity after reconnect
- [ ] PVF-218 [P1] Per-network DNS presets
- [ ] PVF-219 [P1] Captive portal DNS rules
- [ ] PVF-220 [P1] DNSSEC validation if supported

### LIFECYCLE — پایداری و مدیریت اتصال

Priority: P0. Platforms: ALL.

- [ ] PVF-221 [P0] Start/stop idempotence
- [ ] PVF-222 [P0] Cancel while connecting
- [ ] PVF-223 [P0] Auto reconnect with capped backoff
- [ ] PVF-224 [P0] Reconnect after Wi-Fi/cellular switch
- [ ] PVF-225 [P0] Reconnect after sleep/resume
- [ ] PVF-226 [P0] Android Doze/background recovery
- [ ] PVF-227 [P0] Boot start if OS allows
- [ ] PVF-228 [P0] On-demand connection if OS allows
- [ ] PVF-229 [P0] Always-on VPN if available
- [ ] PVF-230 [P0] Kill switch if actually supported
- [ ] PVF-231 [P0] VPN permission denied or revoked handling
- [ ] PVF-232 [P0] Core crash detection
- [ ] PVF-233 [P0] Watchdog health checks
- [ ] PVF-234 [P0] Avoid connection state lies
- [ ] PVF-235 [P0] Cleanup routes/DNS/TUN/system proxy on crash
- [ ] PVF-236 [P0] No file descriptor leaks
- [ ] PVF-237 [P0] Traffic does not die when UI closes
- [ ] PVF-238 [P0] Manual pause
- [ ] PVF-239 [P0] Session duration
- [ ] PVF-240 [P0] Failover with no bypass leak
- [ ] PVF-241 [P0] Captive portal support
- [ ] PVF-242 [P0] Roaming and NAT change handling
- [ ] PVF-243 [P0] Timeout and accurate reasons

### MONITOR — آمار و لاگ و تشخیص

Priority: P1. Platforms: ALL.

- [ ] PVF-244 [P1] Live upload/download speeds
- [ ] PVF-245 [P1] Cumulative traffic session
- [ ] PVF-246 [P1] Traffic history charts
- [ ] PVF-247 [P1] Connection uptime
- [ ] PVF-248 [P1] Active server name and protocol
- [ ] PVF-249 [P1] Exit IP region/ASN
- [ ] PVF-250 [P1] Latency history
- [ ] PVF-251 [P1] Live connections list
- [ ] PVF-252 [P1] Request table HTTP/HTTPS/TCP/UDP metadata
- [ ] PVF-253 [P1] DNS request table
- [ ] PVF-254 [P1] Rule matching and routing trace
- [ ] PVF-255 [P1] Per-process stats where OS supports
- [ ] PVF-256 [P1] Connection search/sort/filter
- [ ] PVF-257 [P1] Manual close connection where supported
- [ ] PVF-258 [P1] Core logs
- [ ] PVF-259 [P1] App logs
- [ ] PVF-260 [P1] Structured diagnostic IDs
- [ ] PVF-261 [P1] Redacted export diagnostics
- [ ] PVF-262 [P1] Self-test wizard
- [ ] PVF-263 [P1] TLS/DNS/route/network checks
- [ ] PVF-264 [P1] Memory/CPU/battery monitor
- [ ] PVF-265 [P1] Alerts when core running but no data path
- [ ] PVF-266 [P1] Privacy-aware limits for packet metadata

### DESKTOP — ویندوز و لینوکس و مک

Priority: P1. Platforms: DESKTOP.

- [ ] PVF-267 [P1] Windows x64/ARM64
- [ ] PVF-268 [P1] macOS Intel/Apple Silicon
- [ ] PVF-269 [P1] Linux x64/ARM64
- [ ] PVF-270 [P1] Desktop system proxy
- [ ] PVF-271 [P1] Desktop TUN via privileged helper
- [ ] PVF-272 [P1] Route and DNS restore on crash
- [ ] PVF-273 [P1] Windows Wintun/WFP where appropriate
- [ ] PVF-274 [P1] Linux TUN and NetworkManager integration
- [ ] PVF-275 [P1] macOS Network Extension
- [ ] PVF-276 [P1] Tray/menu bar controls
- [ ] PVF-277 [P1] Global hotkeys
- [ ] PVF-278 [P1] Launch at login
- [ ] PVF-279 [P1] Notifications and quick toggle
- [ ] PVF-280 [P1] Multi-window and responsive layout
- [ ] PVF-281 [P1] Keyboard navigation
- [ ] PVF-282 [P1] Portable packaging if legal
- [ ] PVF-283 [P1] Signed updater and rollback
- [ ] PVF-284 [P1] CLI integration for power users
- [ ] PVF-285 [P1] Diagnostic helper logs
- [ ] PVF-286 [P1] Clipboard/drag-drop import
- [ ] PVF-287 [P1] Core executable version management
- [ ] PVF-288 [P1] Permission-bounded helper IPC
- [ ] PVF-289 [P1] App-owned system-proxy change tracking

### ANDROID — اندروید

Priority: P1. Platforms: ANDROID.

- [ ] PVF-290 [P1] VpnService and proper socket protection
- [ ] PVF-291 [P1] Foreground notification connection controls
- [ ] PVF-292 [P1] Quick Settings tile
- [ ] PVF-293 [P1] Home widget/launcher shortcuts
- [ ] PVF-294 [P1] Include/exclude apps
- [ ] PVF-295 [P1] Background connection
- [ ] PVF-296 [P1] Always-on and Lockdown via OS settings
- [ ] PVF-297 [P1] Camera QR
- [ ] PVF-298 [P1] Clipboard link detection opt-in
- [ ] PVF-299 [P1] System share target
- [ ] PVF-300 [P1] Android 5/8 floor verification rather than promises
- [ ] PVF-301 [P1] ABI arm64 armv7 x86_64 selection
- [ ] PVF-302 [P1] 16KB native page size
- [ ] PVF-303 [P1] Battery optimization diagnostics
- [ ] PVF-304 [P1] Split-tunnel per app
- [ ] PVF-305 [P1] Connection at boot where legal
- [ ] PVF-306 [P1] Notification permission handling
- [ ] PVF-307 [P1] Android VPN conflict
- [ ] PVF-308 [P1] Tablet/foldable layouts
- [ ] PVF-309 [P1] Android app shortcuts

### TV — Android TV و Google TV

Priority: P1. Platforms: TV.

- [ ] PVF-310 [P1] 10-foot dedicated UI
- [ ] PVF-311 [P1] D-pad-only navigation
- [ ] PVF-312 [P1] Focus management
- [ ] PVF-313 [P1] Large Connect button
- [ ] PVF-314 [P1] Choose server via remote
- [ ] PVF-315 [P1] Favorite/recent nodes
- [ ] PVF-316 [P1] TV QR code import
- [ ] PVF-317 [P1] Mobile-to-TV pairing
- [ ] PVF-318 [P1] Short pairing code
- [ ] PVF-319 [P1] Auto-sync subscriptions
- [ ] PVF-320 [P1] TV-safe settings
- [ ] PVF-321 [P1] Landscape-first display
- [ ] PVF-322 [P1] Android TV launcher metadata
- [ ] PVF-323 [P1] No camera/touch dependency
- [ ] PVF-324 [P1] Remote-based QR export
- [ ] PVF-325 [P1] TV device-network diagnostics

### APPLE — iPhone/iPad/macOS/tvOS

Priority: P1. Platforms: APPLE.

- [ ] PVF-326 [P1] PacketTunnel Network Extension
- [ ] PVF-327 [P1] App Group host-extension sharing
- [ ] PVF-328 [P1] Keychain secrets
- [ ] PVF-329 [P1] iOS privacy prompts
- [ ] PVF-330 [P1] iOS iPad adaptive UI
- [ ] PVF-331 [P1] iCloud backup and sync
- [ ] PVF-332 [P1] Apple TV remote-specific UI
- [ ] PVF-333 [P1] On-demand network triggers
- [ ] PVF-334 [P1] NetworkExtension lifecycle and OS wakes
- [ ] PVF-335 [P1] iOS Files import
- [ ] PVF-336 [P1] Share sheet and deep links
- [ ] PVF-337 [P1] Siri Shortcuts if allowed
- [ ] PVF-338 [P1] Apple Store entitlement and publisher checks
- [ ] PVF-339 [P1] Signed extension notarization where appropriate
- [ ] PVF-340 [P1] Single VPN ownership and conflicts
- [ ] PVF-341 [P1] VoiceOver/Dynamic Type
- [ ] PVF-342 [P1] No unsupported dynamic engine downloading
- [ ] PVF-343 [P1] Explicit unavailable capability flags

### UI — رابط کاربری و شخصی‌سازی

Priority: P1. Platforms: ALL.

- [ ] PVF-344 [P1] PVNetwork original black/gold style
- [ ] PVF-345 [P1] Approved logo unchanged
- [ ] PVF-346 [P1] Persian true RTL
- [ ] PVF-347 [P1] English
- [ ] PVF-348 [P1] Arabic
- [ ] PVF-349 [P1] Turkish
- [ ] PVF-350 [P1] Russian
- [ ] PVF-351 [P1] German
- [ ] PVF-352 [P1] French
- [ ] PVF-353 [P1] Spanish
- [ ] PVF-354 [P1] Chinese
- [ ] PVF-355 [P1] More languages via localization catalogs
- [ ] PVF-356 [P1] Dark/light/system
- [ ] PVF-357 [P1] Accent and accessible contrast
- [ ] PVF-358 [P1] Simple/expert mode
- [ ] PVF-359 [P1] Customizable home cards
- [ ] PVF-360 [P1] Responsive navigation bottom/rail/sidebar
- [ ] PVF-361 [P1] Reduced-motion
- [ ] PVF-362 [P1] Screen-reader labels
- [ ] PVF-363 [P1] Native font scale
- [ ] PVF-364 [P1] Profile icons and flags
- [ ] PVF-365 [P1] App onboarding and contextual help
- [ ] PVF-366 [P1] One-tap connect/disconnect
- [ ] PVF-367 [P1] Consistent error explanations
- [ ] PVF-368 [P1] Auto save preferences
- [ ] PVF-369 [P1] Multilingual RTL/LTR mixed IP URL text
- [ ] PVF-370 [P1] Themes preview and rollback

### SYNC — بکاپ و همگام‌سازی

Priority: P1. Platforms: ALL.

- [ ] PVF-371 [P1] Local backup
- [ ] PVF-372 [P1] Encrypted archive ZIP
- [ ] PVF-373 [P1] Selective profile export
- [ ] PVF-374 [P1] Full settings backup
- [ ] PVF-375 [P1] WebDAV sync
- [ ] PVF-376 [P1] iCloud sync
- [ ] PVF-377 [P1] LAN sync
- [ ] PVF-378 [P1] Pair device with one-time QR
- [ ] PVF-379 [P1] Cross-device profile transfer
- [ ] PVF-380 [P1] Backup integrity manifest
- [ ] PVF-381 [P1] Atomic restore
- [ ] PVF-382 [P1] Restore preview
- [ ] PVF-383 [P1] Versioned migrations
- [ ] PVF-384 [P1] Backup encryption password or recovery key
- [ ] PVF-385 [P1] No secrets included by default
- [ ] PVF-386 [P1] Conflict resolution and history
- [ ] PVF-387 [P1] Export with redact profile secrets
- [ ] PVF-388 [P1] Secure multi-device sync only after explicit consent

### ADV — امکانات بسیار پیشرفته Stash/Shadowrocket

Priority: P2. Platforms: PLATFORM+PERMISSION.

- [ ] PVF-389 [P2] HTTP(S) request inspector on authorized traffic
- [ ] PVF-390 [P2] HTTP Rewrite user-defined
- [ ] PVF-391 [P2] URL rewrite
- [ ] PVF-392 [P2] User-Agent rules
- [ ] PVF-393 [P2] Script filters in sandbox
- [ ] PVF-394 [P2] JavaScript rule engine bounded
- [ ] PVF-395 [P2] Certificate-based optional user-authorized TLS inspection
- [ ] PVF-396 [P2] No covert HTTPS interception
- [ ] PVF-397 [P2] Controlled content-filtering extensions
- [ ] PVF-398 [P2] Ad blocker optional
- [ ] PVF-399 [P2] Custom hosts and DNS mapping
- [ ] PVF-400 [P2] Multi-level forward proxy
- [ ] PVF-401 [P2] SSID policy groups
- [ ] PVF-402 [P2] Advanced override editor
- [ ] PVF-403 [P2] MitM diagnosis only with explicit opt-in and legal policy
- [ ] PVF-404 [P2] Credential/secret-safe capture export
- [ ] PVF-405 [P2] Optional local proxy server with authentication
- [ ] PVF-406 [P2] Unsafe scripts disabled by default
- [ ] PVF-407 [P2] HTTP request test/replay for own endpoints

### ACCOUNT — حساب و فروشگاه PVNetwork

Priority: P1. Platforms: PVNETWORK.

- [ ] PVF-408 [P1] Guest mode preserved
- [ ] PVF-409 [P1] Optional user login
- [ ] PVF-410 [P1] User registration and logout
- [ ] PVF-411 [P1] Customer token session handling
- [ ] PVF-412 [P1] Device pairing and registration
- [ ] PVF-413 [P1] Active device list and revoke
- [ ] PVF-414 [P1] Service cards by location
- [ ] PVF-415 [P1] Customer traffic quota/expiry
- [ ] PVF-416 [P1] Plan catalog from backend
- [ ] PVF-417 [P1] Renewal/extra traffic flow
- [ ] PVF-418 [P1] Price display per backend audience
- [ ] PVF-419 [P1] Payment compliant with each Store
- [ ] PVF-420 [P1] Invoices and receipts
- [ ] PVF-421 [P1] Auto provisioning of user configs
- [ ] PVF-422 [P1] Customer support tickets
- [ ] PVF-423 [P1] One-click subscription sync
- [ ] PVF-424 [P1] Optional push expiration reminders
- [ ] PVF-425 [P1] Privacy policy and account deletion
- [ ] PVF-426 [P1] Error notice for infrastructure outages
- [ ] PVF-427 [P1] No admin credential in consumer application
- [ ] PVF-428 [P1] Access to several customer services under one account

### OPS — سازگاری پنل‌ها و زیرساخت

Priority: P2. Platforms: BACKEND.

- [ ] PVF-429 [P2] Import 3x-ui subscription
- [ ] PVF-430 [P2] Mirza user subscription integration
- [ ] PVF-431 [P2] OV-PvNetwork customer API
- [ ] PVF-432 [P2] PVNaive NaiveProxy provisioning
- [ ] PVF-433 [P2] User-Agent subscription output negotiation
- [ ] PVF-434 [P2] Node pool health monitoring
- [ ] PVF-435 [P2] Signed node manifests
- [ ] PVF-436 [P2] Customer-only tokens not admin APIs
- [ ] PVF-437 [P2] Subscription outage fallback
- [ ] PVF-438 [P2] Multiple region selection
- [ ] PVF-439 [P2] Device concurrency status as server truth
- [ ] PVF-440 [P2] Correct add-vs-set quota renewal
- [ ] PVF-441 [P2] Bandwidth usage from authoritative backend
- [ ] PVF-442 [P2] No infrastructure secrets in app
- [ ] PVF-443 [P2] Graceful handling of ISP outages
- [ ] PVF-444 [P2] Multi-panel service presence without privileged access
- [ ] PVF-445 [P2] Backend versioned endpoints
- [ ] PVF-446 [P2] Operator-side optional uplink routing and failover

### SELFHOST — راه‌اندازی سرور شخصی

Priority: P2. Platforms: AUTHORIZED_SERVER.

- [ ] PVF-447 [P2] Connect to self-hosted VPS
- [ ] PVF-448 [P2] Server wizard with secure SSH verification
- [ ] PVF-449 [P2] Install WireGuard on owned server
- [ ] PVF-450 [P2] Install OpenVPN on owned server
- [ ] PVF-451 [P2] Install AmneziaWG on owned server
- [ ] PVF-452 [P2] Install Xray on owned server
- [ ] PVF-453 [P2] Container provisioning with license review
- [ ] PVF-454 [P2] Firewall and ports preview
- [ ] PVF-455 [P2] Rollback server changes
- [ ] PVF-456 [P2] Backup server configs
- [ ] PVF-457 [P2] Server health dashboard
- [ ] PVF-458 [P2] Issue per-user QR from authorized admin API
- [ ] PVF-459 [P2] Server TLS certificate checks
- [ ] PVF-460 [P2] Import existing server without reinstallation
- [ ] PVF-461 [P2] Keep SSH credentials out of mobile client after provisioning

### ENTERPRISE — اتصال سازمانی

Priority: P2. Platforms: OS+POLICY.

- [ ] PVF-462 [P2] OpenConnect server family profiles
- [ ] PVF-463 [P2] SAML/OIDC SSO
- [ ] PVF-464 [P2] MFA TOTP push authenticator
- [ ] PVF-465 [P2] External browser login
- [ ] PVF-466 [P2] Client certificate enrollment
- [ ] PVF-467 [P2] Hardware key auth if OS supports
- [ ] PVF-468 [P2] Managed device VPN profiles
- [ ] PVF-469 [P2] MDM integrations
- [ ] PVF-470 [P2] Enterprise split DNS
- [ ] PVF-471 [P2] Enterprise proxy PAC
- [ ] PVF-472 [P2] Device posture checks via approved API
- [ ] PVF-473 [P2] Private enterprise certificate trust configuration
- [ ] PVF-474 [P2] SSO token revocation
- [ ] PVF-475 [P2] Compliance audit logging without secrets
- [ ] PVF-476 [P2] Corporate Always-on policy when supported

### RELEASE — آزمون امنیت و انتشار

Priority: P0. Platforms: ALL.

- [ ] PVF-477 [P0] Green reproducible CI per OS
- [ ] PVF-478 [P0] Artifact pinned by exact commit SHA
- [ ] PVF-479 [P0] Native engine class/ABI verification
- [ ] PVF-480 [P0] Dependency SBOM
- [ ] PVF-481 [P0] Supply chain vulnerability audit
- [ ] PVF-482 [P0] Real device tunnel test
- [ ] PVF-483 [P0] IPv4 and IPv6 traffic test
- [ ] PVF-484 [P0] DNS leak regression
- [ ] PVF-485 [P0] Socket protection/routing loop regression
- [ ] PVF-486 [P0] Local unauthenticated proxy isolation
- [ ] PVF-487 [P0] Malformed config fuzzing
- [ ] PVF-488 [P0] Credential extraction/redaction test
- [ ] PVF-489 [P0] Secret deletion test
- [ ] PVF-490 [P0] Network switch/Doze/process kill tests
- [ ] PVF-491 [P0] High-concurrency connect/cancel tests
- [ ] PVF-492 [P0] Profile migration/corruption recovery
- [ ] PVF-493 [P0] 100+ repeat cycles selected scenarios
- [ ] PVF-494 [P0] 1h/24h soak scenarios on device
- [ ] PVF-495 [P0] Real speed/memory/battery baselines
- [ ] PVF-496 [P0] Accessibility and RTL tests
- [ ] PVF-497 [P0] App signing and notarization
- [ ] PVF-498 [P0] Apple/Google VPN store declaration
- [ ] PVF-499 [P0] Open source commercial license review
- [ ] PVF-500 [P0] Privacy/data deletion/security review
- [ ] PVF-501 [P0] Release candidate rollout and rollback
- [ ] PVF-502 [P0] Versioned supported-capabilities table
- [ ] PVF-503 [P0] No shell app called production VPN

## Competitor reference map

| Reference | Feature areas |
|---|---|
| Karing | Import, subscriptions, grouping, smart routing, WebDAV/iCloud/LAN sync, novice UX, Apple TV |
| Hiddify | Modern protocols, best-node auto selection, broad platform UI and usage/expiry display |
| v2rayNG and v2rayN | Xray profiles, subscriptions, GeoIP/GeoSite, desktop/Android controls |
| FlClash and Clash Verge Rev | Mihomo rules, groups, merge/scripts, live connections and DNS, TUN/system proxy, tray and WebDAV |
| Shadowrocket and Stash | Expert routing, request inspection, DNS and optional rewriting/scripting/authorized diagnostic TLS interception |
| OpenVPN Connect and OpenConnect | OpenVPN files, certs, enterprise authentication/SSO/MFA and family-specific connectivity |
| WireGuard and AmneziaVPN | WireGuard profiles, roaming, obfuscation, self-hosted provisioning and split tunneling |
| NekoBox/NekoRay, V2Box, Happ, Streisand and FoXray | Expert import / VPN UX and protocol compatibility references; proprietary formats need valid provenance |
| PVNetwork Mirza, OV-PvNetwork, 3x-ui, PVNaive | Customer entitlement, quota, region selection, secure subscription APIs and account catalog |

## Links to official primary documentation

- https://github.com/KaringX/karing and https://karing.app/en/quickstart
- https://github.com/hiddify/hiddify-app
- https://github.com/2dust/v2rayNG and https://github.com/2dust/v2rayN
- https://github.com/chen08209/FlClash/releases and https://github.com/clash-verge-rev/clash-verge-rev
- https://github.com/WireGuard/wireguard-android
- https://openvpn.net/connect-docs/user-guide.html
- https://www.infradead.org/openconnect/protocols.html
- https://docs.amnezia.org/documentation/instructions/install-configure-protocols/
- https://apps.apple.com/us/app/stash-rule-based-proxy/id1596063349
- https://apps.apple.com/us/app/shadowrocket/id932747118

## Strict implementation policy

- Secure socket/TUN and localhost proxy defects identified in docs/audits/2026-10-27-ANDROID-DEFECTS.md must be repaired before any broad protocol release.
- Profiles may be recognized as formats without being runnable; do not confuse parsing with connectivity.
- A checked P0/P1 protocol item must have source, CI, on-device traffic, DNS and routing, disconnect/reconnect and secrets evidence for the named engine/OS/version.
- Expert script/MITM/SSL capture features require explicit user authorization, sandbox, platform eligibility and Store/legal review; disabled by default.
- Existing Android build CI is RED on September 17, 2026 at run 35177021596 (file_picker Java plugin registration), and no actual device VPN proof was available when this catalog was authored.
- Prioritize stages: (0) CI/security/native tunnel, (1) first verified Xray connection, (2) subscriptions/import/QR/RTL, (3) OpenVPN/WireGuard and modern cores, (4) routing/DNS/power features, (5) native OS/TV and PVNetwork integration, (6) release gates.

Total: **503 individually trackable features** in **25 domains**.
