#!/usr/bin/env python3
from pathlib import Path
import shutil
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: brand_sfa.py <sfa-root> <logo-file>")

root = Path(sys.argv[1]).resolve()
logo = Path(sys.argv[2]).resolve()
app = root / "app"
if not app.exists():
    raise SystemExit(f"SFA app dir not found: {app}")
if not logo.exists():
    raise SystemExit(f"logo not found: {logo}")

gradle = app / "build.gradle.kts"
text = gradle.read_text(encoding="utf-8")
text = text.replace('applicationId = "io.nekohasekai.sfa"', 'applicationId = "com.pvnetwork.vpn"')
text = text.replace('base.archivesName.set("SFA-${versionName}")', 'base.archivesName.set("PVNetwork-VPN-${versionName}")')
# GitHub-hosted Android SDK currently exposes stable API 36; keep the client
# Play-compatible while avoiding unreleased API 37 compile dependencies.
text = text.replace("compileSdk = 37", "compileSdk = 36")
text = text.replace("    compileSdkMinor = 1\n", "")
text = text.replace("targetSdk = 37", "targetSdk = 36")
gradle.write_text(text, encoding="utf-8")

drawable = app / "src/main/res/drawable-nodpi"
drawable.mkdir(parents=True, exist_ok=True)
shutil.copy2(logo, drawable / "private_network_logo.jpg")

strings = app / "src/main/res/values/strings.xml"
text = strings.read_text(encoding="utf-8")
text = text.replace(
    '<string name="app_name" translatable="false">sing-box</string>',
    '<string name="app_name" translatable="false">PVNetwork VPN</string>'
)
strings.write_text(text, encoding="utf-8")

color_file = app / "src/main/java/io/nekohasekai/sfa/compose/theme/Color.kt"
text = color_file.read_text(encoding="utf-8")
text = text.replace("Color(0xFFD81B60)", "Color(0xFFFFB52E)")
text = text.replace("Color(0xFFA00037)", "Color(0xFFB87800)")
text = text.replace("Color(0xFFFF5C8D)", "Color(0xFFFFD36A)")
color_file.write_text(text, encoding="utf-8")

theme_file = app / "src/main/java/io/nekohasekai/sfa/compose/theme/Theme.kt"
text = theme_file.read_text(encoding="utf-8")
text = text.replace("dynamicColor: Boolean = true", "dynamicColor: Boolean = false")
if "import androidx.compose.ui.graphics.Color" not in text:
    text = text.replace(
        "import androidx.compose.ui.graphics.toArgb",
        "import androidx.compose.ui.graphics.Color\nimport androidx.compose.ui.graphics.toArgb"
    )
old_dark = '''private val DarkColorScheme =
    darkColorScheme(
        primary = SingBoxPrimary,
        secondary = SingBoxPrimaryLight,
        tertiary = LogBlue,
    )'''
new_dark = '''private val DarkColorScheme =
    darkColorScheme(
        primary = SingBoxPrimary,
        onPrimary = Color(0xFF160F00),
        primaryContainer = Color(0xFF4B3200),
        onPrimaryContainer = Color(0xFFFFE0A1),
        secondary = SingBoxPrimaryLight,
        tertiary = Color(0xFFFFC95A),
        background = Color(0xFF060606),
        onBackground = Color(0xFFF7F2E8),
        surface = Color(0xFF0D0D0D),
        onSurface = Color(0xFFF7F2E8),
        surfaceVariant = Color(0xFF181510),
        onSurfaceVariant = Color(0xFFD7CCB7),
        outline = Color(0xFF755B2B),
    )'''
text = text.replace(old_dark, new_dark)
old_light = '''private val LightColorScheme =
    lightColorScheme(
        primary = SingBoxPrimary,
        secondary = SingBoxPrimaryDark,
        tertiary = LogBlue,
    )'''
new_light = '''private val LightColorScheme =
    lightColorScheme(
        primary = Color(0xFF9B6200),
        onPrimary = Color.White,
        secondary = Color(0xFF7B5716),
        tertiary = Color(0xFF8E6500),
        background = Color(0xFFFFFBF5),
        surface = Color(0xFFFFFBF5),
        surfaceVariant = Color(0xFFF2E7D4),
        outline = Color(0xFF806D4A),
    )'''
text = text.replace(old_light, new_light)
theme_file.write_text(text, encoding="utf-8")

manifest = app / "src/main/AndroidManifest.xml"
text = manifest.read_text(encoding="utf-8")
feature_anchor = '''<uses-feature
        android:name="android.hardware.camera"
        android:required="false" />'''
features = feature_anchor + '''
    <uses-feature
        android:name="android.software.leanback"
        android:required="false" />
    <uses-feature
        android:name="android.hardware.touchscreen"
        android:required="false" />'''
text = text.replace(feature_anchor, features)
text = text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@drawable/private_network_logo"')
text = text.replace(
    'android:label="@string/app_name"\n        android:supportsRtl="true"',
    'android:label="@string/app_name"\n        android:roundIcon="@drawable/private_network_logo"\n        android:supportsRtl="true"'
)
launcher = '<category android:name="android.intent.category.LAUNCHER" />'
if "android.intent.category.LEANBACK_LAUNCHER" not in text:
    text = text.replace(
        launcher,
        launcher + '\n                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />',
        1
    )
manifest.write_text(text, encoding="utf-8")

dashboard = app / "src/main/java/io/nekohasekai/sfa/compose/screen/dashboard/DashboardScreen.kt"
text = dashboard.read_text(encoding="utf-8")
imports = {
    "import androidx.compose.foundation.Image": "import androidx.compose.foundation.layout.Arrangement",
    "import androidx.compose.ui.layout.ContentScale": "import androidx.compose.ui.Modifier",
    "import androidx.compose.ui.res.painterResource": "import androidx.compose.ui.platform.LocalContext",
}
for addition, anchor in imports.items():
    if addition not in text:
        text = text.replace(anchor, addition + "\n" + anchor)
hero = '''            item {
                Image(
                    painter = painterResource(R.drawable.private_network_logo),
                    contentDescription = "PVNetwork VPN",
                    modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
                    contentScale = ContentScale.FillWidth,
                )
            }

'''
marker = "            // Dynamic dashboard cards\n"
if hero.strip() not in text:
    text = text.replace(marker, hero + marker)
dashboard.write_text(text, encoding="utf-8")

print("PVNetwork branding patch applied to real SFA/sing-box client.")
