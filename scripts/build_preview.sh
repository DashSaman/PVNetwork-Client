#!/usr/bin/env bash
set -euo pipefail

OUT="PVNetwork-VPN-v0.1-preview-arm64.apk"

python3 -m pip install --disable-pip-version-check pillow

yes | sdkmanager --licenses >/dev/null || true
sdkmanager "build-tools;36.0.0"
export PATH="$ANDROID_HOME/build-tools/36.0.0:$PATH"

curl -L --fail --retry 4 -o upstream.apk "https://github.com/amnezia-vpn/amnezia-client/releases/download/5.0.0.5/AmneziaVPN_5.0.0.5_android9%2B_arm64-v8a.apk"
echo "27703c69767031a632272c50eedc5627f8a1961db55a1099dade5a4bcab57f42  upstream.apk" | sha256sum -c -

curl -L --fail --retry 4 -o apktool.jar "https://github.com/iBotPeaches/Apktool/releases/download/v3.0.3/apktool_3.0.3.jar"

java -jar apktool.jar d -f upstream.apk -o decoded
python3 scripts/patch_decoded_apk.py decoded
java -jar apktool.jar b decoded -o unsigned.apk

keytool -genkeypair -v -keystore pvnetwork-preview.jks -storepass pvnetwork-preview -keypass pvnetwork-preview -alias pvnetwork-preview -keyalg RSA -keysize 2048 -validity 3650 -dname "CN=PVNetwork Preview, O=PVNetwork"

zipalign -f -p 4 unsigned.apk aligned.apk
apksigner sign --ks pvnetwork-preview.jks --ks-pass pass:pvnetwork-preview --key-pass pass:pvnetwork-preview --out "$OUT" aligned.apk
apksigner verify --verbose --print-certs "$OUT"
sha256sum "$OUT" | tee SHA256SUMS.txt
