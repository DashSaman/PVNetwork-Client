#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# PVNetwork — host project bootstrap for the universal Flutter client.
#
# Creates (or refreshes) the Flutter host projects inside universal/ (or a
# CI-provided target directory), applies the Android patches that wire the
# first-party pvxray core (MethodChannel plugin + VpnService), and installs
# the AAR artifact when it is available.
#
# Usage:
#   scripts/setup_host_projects.sh [platforms]          # local dev
#   TARGET=buildhost scripts/setup_host_projects.sh android   # CI override
#   PLATFORMS defaults to "android"; local devs may pass e.g. "android,windows,linux,macos,ios"
# ---------------------------------------------------------------------------
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLATFORMS="${1:-android}"
TARGET_DIR="${TARGET:-$ROOT/universal}"
PATCHES="$ROOT/universal/patches/android"
KT_DIR="$TARGET_DIR/android/app/src/main/kotlin/com/pvnetwork/vpn"

command -v flutter >/dev/null 2>&1 || { echo "flutter is not on PATH" >&2; exit 1; }

mkdir -p "$TARGET_DIR"
echo "[pv] Creating host projects ($PLATFORMS) in $TARGET_DIR"
(cd "$TARGET_DIR" && flutter create --org com.pvnetwork --project-name vpn --platforms="$PLATFORMS" .)

# flutter create drops a default test/widget_test.dart referencing MyApp; the
# PVNetwork test suite replaces it.
rm -f "$TARGET_DIR/test/widget_test.dart"

if [[ -d "$PATCHES" ]]; then
  echo "[pv] Applying Android patches"
  mkdir -p "$KT_DIR"
  cp "$PATCHES/MainActivity.kt" "$PATCHES/PvxrayBridge.kt" "$PATCHES/PvxrayPlugin.kt" "$PATCHES/PVVpnService.kt" "$KT_DIR/"

  MANIFEST="$TARGET_DIR/android/app/src/main/AndroidManifest.xml"
  if [[ -f "$MANIFEST" ]] && ! grep -q "PVVpnService" "$MANIFEST"; then
    python3 - "$MANIFEST" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
service = '''        <service
            android:name=".PVVpnService"
            android:exported="false"
            android:foregroundServiceType="systemExempted"
            android:permission="android.permission.BIND_VPN_SERVICE">
            <intent-filter>
                <action android:name="android.net.VpnService" />
            </intent-filter>
        </service>
'''
assert '</application>' in text, 'unexpected AndroidManifest layout'
text = text.replace('</application>', service + '    </application>', 1)
permissions = [
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_SYSTEM_EXEMPTED',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.INTERNET',
]
missing = [p for p in permissions if f'android:name="{p}"' not in text]
if missing:
    insert = ''.join(f'    <uses-permission android:name="{p}" />\n' for p in missing)
    assert '</manifest>' in text
    text = text.replace('</manifest>', insert + '</manifest>', 1)
open(path, 'w').write(text)
print('[pv] PVVpnService registered in AndroidManifest (FGS type + permissions)')
PY
  fi
fi

# Install the core AAR when a built artifact is present (CI or local gomobile bind).
AAR="$ROOT/core/xray-mobile/dist/pvxray.aar"
if [[ -f "$AAR" ]]; then
  echo "[pv] Installing pvxray.aar"
  mkdir -p "$TARGET_DIR/android/app/libs"
  cp "$AAR" "$TARGET_DIR/android/app/libs/pvxray.aar"
  GRADLE_FILE="$TARGET_DIR/android/app/build.gradle.kts"
  if [[ -f "$GRADLE_FILE" ]] && ! grep -q "libs/pvxray.aar" "$GRADLE_FILE"; then
    python3 - "$GRADLE_FILE" <<'PY'
import re
import sys
path = sys.argv[1]
text = open(path).read()
block = '\n    implementation(files("libs/pvxray.aar"))'
m = re.search(r'\bdependencies\s*\{', text)
if m:
    text = text[:m.end()] + block + text[m.end():]
    print('[pv] pvxray.aar injected into existing dependencies block')
else:
    text += '\ndependencies {\n    implementation(files("libs/pvxray.aar"))\n}\n'
    print('[pv] pvxray.aar appended as a new dependencies block')
open(path, 'w').write(text)
PY
  fi
else
  echo "[pv] No pvxray.aar found (run core/xray-mobile CI or gomobile bind locally);"
  echo "     the app will build and run, and report the engine as unavailable until the AAR ships."
fi

echo "[pv] flutter pub get"
(cd "$TARGET_DIR" && flutter pub get)

echo "[pv] Host project ready: $TARGET_DIR"
