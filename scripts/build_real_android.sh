#!/usr/bin/env bash
set -euxo pipefail

ROOT="$(pwd)"
BUILD="$ROOT/_build"
DIST="$ROOT/dist"
ASSETS="$ROOT/_build_assets"
rm -rf "$BUILD" "$DIST" "$ASSETS"
mkdir -p "$BUILD" "$DIST" "$ASSETS"

# Exact PVNetwork artwork is versioned in the pvnetwork-v0.3 branch.
curl -L --fail --retry 3 \
  https://raw.githubusercontent.com/DashSaman/PVNetwork-Client/pvnetwork-v0.3/branding/private-network-logo.jpg \
  -o "$ASSETS/private-network-logo.jpg"
test -s "$ASSETS/private-network-logo.jpg"

git clone https://github.com/SagerNet/sing-box.git "$BUILD/sing-box"
git -C "$BUILD/sing-box" checkout v1.13.18
git clone https://github.com/SagerNet/sing-box-for-android.git "$BUILD/sing-box-for-android"
git -C "$BUILD/sing-box-for-android" checkout 0a401b69b63d5bc40be5c018baa117a04eeb26a1

python3 "$ROOT/scripts/brand_sfa.py" "$BUILD/sing-box-for-android" "$ASSETS/private-network-logo.jpg"

command -v go
go version
export GOTOOLCHAIN=auto

yes | sdkmanager --licenses >/dev/null || true
sdkmanager "platform-tools" "platforms;android-37" "build-tools;37.0.0" "ndk;28.0.13004108"

go install github.com/sagernet/gomobile/cmd/gomobile@v0.1.12
go install github.com/sagernet/gomobile/cmd/gobind@v0.1.12
"$(go env GOPATH)/bin/gomobile" init

(
  cd "$BUILD/sing-box"
  go run ./cmd/internal/build_libbox -target android
)

test -s "$BUILD/sing-box-for-android/app/libs/libbox.aar"
test -s "$BUILD/sing-box-for-android/app/libs/libbox-legacy.aar"

(
  cd "$BUILD/sing-box-for-android"
  chmod +x gradlew
  ./gradlew :app:assembleOtherDebug :app:assembleOtherLegacyDebug --stacktrace --no-daemon
)

STANDARD="$(find "$BUILD/sing-box-for-android/app/build/outputs/apk/other/debug" -type f -name '*universal*.apk' | head -n1)"
LEGACY="$(find "$BUILD/sing-box-for-android/app/build/outputs/apk/otherLegacy/debug" -type f -name '*universal*.apk' | head -n1)"
test -s "$STANDARD"
test -s "$LEGACY"
cp "$STANDARD" "$DIST/PVNetwork-VPN-v0.3-android6plus-universal.apk"
cp "$LEGACY" "$DIST/PVNetwork-VPN-v0.3-android5plus-legacy-universal.apk"
sha256sum "$DIST"/*.apk > "$DIST/SHA256SUMS.txt"
cat > "$DIST/BUILD_INFO.txt" <<EOF
PVNetwork VPN V0.3
Application ID: com.pvnetwork.vpn
SFA: 0a401b69b63d5bc40be5c018baa117a04eeb26a1
sing-box: v1.13.18
Standard minSdk: 23
Legacy minSdk: 21
Universal ABIs: armeabi-v7a, arm64-v8a, x86, x86_64
OpenVPN engine: not bundled in V0.3
EOF
ls -lh "$DIST"
