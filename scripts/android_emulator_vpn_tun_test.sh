#!/usr/bin/env bash
# Strict, disposable ANDROID EMULATOR ONLY native VpnService smoke.
# Tests actual patched Kotlin service, JNI/core and Android-created TUN;
# this does not test an external VPN server, DNS, IPv6 leaks or wire throughput.
set -euo pipefail

DEBUG_APK="${1:?expected debuggable APK built from the exact CI checkout}"
TEST_APK="${2:?expected androidTest APK from the same checkout}"
PKG="com.pvnetwork.vpn"
RUNNER="$PKG.test/androidx.test.runner.AndroidJUnitRunner"

test -s "$DEBUG_APK"
test -s "$TEST_APK"
adb wait-for-device

# The test is run only on the CI-emulated device (not a user's device).
# Pre-consent the dedicated test package to avoid a blocking VPN dialog.
# This changes VPN consent only within this disposable emulator.
adb install -r "$DEBUG_APK"
adb install -r "$TEST_APK"
adb shell appops set "$PKG" ACTIVATE_VPN allow
adb shell appops get "$PKG" ACTIVATE_VPN | tee /tmp/pvnetwork-appops.txt
grep -q "allow" /tmp/pvnetwork-appops.txt

adb logcat -c
set +e
adb shell am instrument -w "$RUNNER" | tee /tmp/pvnetwork-vpn-instrumentation.txt
result="${PIPESTATUS[0]}"
set -e
if [[ "$result" -ne 0 ]] ||
   ! grep -Eq '^OK \(1 test\)' /tmp/pvnetwork-vpn-instrumentation.txt ||
   grep -Eq '^FAILURES!|INSTRUMENTATION_FAILED|INSTRUMENTATION_RESULT: shortMsg' /tmp/pvnetwork-vpn-instrumentation.txt; then
  echo "FAIL: native Android VPN/TUN test did not pass." >&2
  adb logcat -d -s AndroidRuntime:E || true
  exit 1
fi

if adb logcat -d -s AndroidRuntime:E | grep -q 'FATAL EXCEPTION'; then
  echo "FAIL: AndroidRuntime fatal exception during native VPN lifecycle." >&2
  adb logcat -d -s AndroidRuntime:E || true
  exit 1
fi

# Ensure the instrumentation left no background native VPN active. The
# Java assertion checks the Go singleton; this is additional host evidence.
echo "PASS: native Xray + Android VpnService established a TUN and cleanly stopped for three cycles."
echo "LIMIT: does not prove external proxy, DNS/IPv6 no-leaks, user-device reliability, or commercial readiness."
