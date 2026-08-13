# PVNetwork Cross-Platform Builds

PVNetwork VPN is being developed as an independent cross-platform client with application identifier `com.pvnetwork.vpn`.

## Release outputs

The `PVNetwork Universal Release` GitHub Actions workflow publishes:

- `PVNetwork-VPN-Android.apk`
- `PVNetwork-VPN-Windows-x64.zip`
- `PVNetwork-VPN-Linux-x64.tar.gz`
- `PVNetwork-VPN-macOS.zip`
- `PVNetwork-VPN-iOS-Unsigned.zip`
- `SHA256SUMS.txt`

## iOS

The iOS artifact is unsigned because no Apple Developer certificate or provisioning profile is stored in this repository. A normal installable IPA/TestFlight build requires Apple signing credentials. Those credentials should later be stored as protected GitHub Actions secrets, never committed to source control.

## Current product stage

Version 0.2.0 is the independent PVNetwork cross-platform foundation. It establishes branding, package identity, reproducible desktop/mobile builds, and release infrastructure. Protocol engines are not represented as active until their direct integrations are implemented and tested.

## فارسی

Workflow چندپلتفرمی ریپو خروجی Android، Windows، Linux، macOS و نسخه unsigned برای iOS را می‌سازد و در GitHub Releases منتشر می‌کند. فایل iOS بدون امضای Apple است؛ برای IPA قابل نصب روی آیفون باید Certificate و Provisioning Profile معتبر Apple Developer به صورت Secret به CI اضافه شود.

نسخه 0.2.0 پایه مستقل و چندپلتفرمی PVNetwork است. تا قبل از ادغام و تست واقعی هسته‌های پروتکل، ادعای اتصال واقعی VPN در این نسخه نمی‌شود.
