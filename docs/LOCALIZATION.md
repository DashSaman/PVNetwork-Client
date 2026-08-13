# Localization

V0.2 ships resource files for:
- English (default)
- Persian / فارسی
- Arabic / العربية
- Turkish / Türkçe
- Russian / Русский
- German / Deutsch
- French / Français
- Spanish / Español
- Simplified Chinese / 简体中文

Android selects language from the device locale. `supportsRtl=true` enables layout direction for Persian and Arabic.

## Rule
User-visible text must live in Android string resources. New UI must not hard-code visible English strings in Java except technical protocol identifiers.

Future gate: in-app language override and additional community translations.
