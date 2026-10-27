#!/usr/bin/env bash
# Android emulator install/launch smoke gate for the EXACT APK artifact from CI.
# This verifies installability and startup only: NOT a VPN tunnel E2E receipt.
set -euo pipefail

APK="${1:-dist/PVNetwork-Android-dev.apk}"
PKG="com.pvnetwork.vpn"
test -s "$APK" || { echo "Missing test APK: $APK" >&2; exit 1; }

adb wait-for-device
adb install -r "$APK"
adb shell pm path "$PKG" | grep -q '^package:'
adb logcat -c
adb shell am start -W -n "$PKG/.MainActivity"
sleep 8

if ! adb shell pidof "$PKG" >/dev/null; then
  echo "Android application terminated shortly after launch." >&2
  adb logcat -d -s AndroidRuntime:E || true
  exit 1
fi

# The tagged AndroidRuntime crash signal covers fatal Java/Kotlin crashes in
# Flutter plugin registration and app initialization. This is not a substitute
# for UI/instrumentation, permission or real proxy-traffic checks.
if adb logcat -d -s AndroidRuntime:E | grep -q 'FATAL EXCEPTION'; then
  echo "Fatal Android runtime exception detected after startup." >&2
  adb logcat -d -s AndroidRuntime:E || true
  exit 1
fi

echo "PASS: app installed, launched and stayed alive on emulator."
echo "LIMIT: no VPN permission, tunnel, DNS or egress traffic was tested."
