# PVNetwork VPN

<p align="center">
  <img src="https://raw.githubusercontent.com/DashSaman/PVNetwork-Client/pvnetwork-v0.3/branding/private-network-logo.jpg" width="320" alt="PVNetwork VPN">
</p>

**Black & Gold Universal VPN Client**

English · فارسی · العربية · Türkçe · Русский · Deutsch · Français · Español · 中文

## English
PVNetwork VPN is a public multi-protocol VPN client. V0.3 replaces the old UI-only prototype with a real Android VPN engine based on pinned SFA/sing-box sources. It targets phones, tablets and Android TV/boxes. The universal legacy APK is designed for Android 5+ and includes ARM64, ARMv7, x86 and x86_64.

The sing-box engine covers modern protocol families such as VLESS/Reality, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS and WireGuard. OpenVPN `.ovpn` is a separate engine integration and is not claimed as active until that adapter is completed and tested.

## فارسی
PVNetwork VPN یک کلاینت عمومی و چندپروتکلی با تم مشکی/طلایی است. نسخه V0.3 پوسته‌ی آزمایشی قبلی را کنار گذاشته و از موتور واقعی Android VPN مبتنی بر SFA/sing-box استفاده می‌کند. هدف: موبایل، تبلت، Android TV و باکس؛ خروجی Universal Legacy برای Android 5+ و معماری‌های ARM64، ARMv7، x86 و x86_64 ساخته می‌شود.

هسته sing-box خانواده‌های VLESS/Reality، VMess، Trojan، Shadowsocks، Hysteria2، TUIC، AnyTLS و WireGuard را پوشش می‌دهد. OpenVPN و فایل `.ovpn` با موتور مستقل اضافه می‌شود و تا قبل از تکمیل و تست، به‌عنوان قابلیت فعال اعلام نمی‌شود.

## العربية
PVNetwork VPN عميل VPN عام متعدد البروتوكولات بتصميم أسود وذهبي. يستخدم V0.3 محرك Android VPN حقيقي مبنياً على SFA/sing-box ويدعم الهاتف واللوحي وAndroid TV. إصدار Legacy Universal يستهدف Android 5+ ومعماريات ARM64 وARMv7 وx86 وx86_64. سيضاف OpenVPN/`.ovpn` كمحرك مستقل بعد الاختبار.

## Türkçe
PVNetwork VPN siyah/altın temalı, genel kullanıma açık çok protokollü bir VPN istemcisidir. V0.3 gerçek SFA/sing-box Android VPN motorunu kullanır; telefon, tablet ve Android TV hedeflenir. Legacy Universal paket Android 5+ içindir. OpenVPN/`.ovpn` ayrı bir motor olarak test edildikten sonra eklenir.

## Русский
PVNetwork VPN — публичный мультипротокольный VPN-клиент в чёрно-золотом стиле. V0.3 использует реальный Android VPN-движок SFA/sing-box и предназначен для телефонов, планшетов и Android TV. Legacy Universal рассчитан на Android 5+. OpenVPN/`.ovpn` добавляется отдельным движком после тестирования.

## Deutsch
PVNetwork VPN ist ein öffentlicher Multi-Protokoll-VPN-Client im Schwarz-Gold-Design. V0.3 verwendet die echte SFA/sing-box Android-VPN-Engine für Smartphone, Tablet und Android TV. Die Legacy-Universal-Version zielt auf Android 5+. OpenVPN/`.ovpn` folgt als separat getestete Engine.

## Français
PVNetwork VPN est un client VPN public multi-protocoles au thème noir et or. V0.3 utilise le véritable moteur VPN Android SFA/sing-box pour téléphone, tablette et Android TV. La version Legacy Universal cible Android 5+. OpenVPN/`.ovpn` sera ajouté comme moteur séparé après validation.

## Español
PVNetwork VPN es un cliente VPN público multiprotocolo con tema negro y dorado. V0.3 usa el motor VPN Android real SFA/sing-box para teléfonos, tabletas y Android TV. La versión Legacy Universal apunta a Android 5+. OpenVPN/`.ovpn` se añadirá como motor separado tras sus pruebas.

## 中文
PVNetwork VPN 是一款黑金主题的公共多协议 VPN 客户端。V0.3 使用真实的 SFA/sing-box Android VPN 引擎，面向手机、平板和 Android TV。Legacy Universal 版本面向 Android 5+。OpenVPN/`.ovpn` 将作为独立引擎完成测试后加入。

## Reproducible Android build
- Application ID: `com.pvnetwork.vpn`
- SFA commit: `0a401b69b63d5bc40be5c018baa117a04eeb26a1`
- sing-box: `v1.13.18`
- Android compile/target SDK: 36
- Standard minSdk: 23 (Android 6+)
- Legacy minSdk: 21 (Android 5+)
- Branding patch: `scripts/brand_sfa.py`
- Build orchestrator: `scripts/build_real_android.sh`

Builds are produced by GitHub Actions and stored under `releases/` after successful validation.

## License
The Android networking base uses GPL-3.0 licensed SagerNet projects. PVNetwork branding and project-specific integration are maintained in this repository. Hiddify source code is not included.
