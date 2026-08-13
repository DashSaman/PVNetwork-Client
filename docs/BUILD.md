# Build

## CI
Workflow: `.github/workflows/android-ci.yml`

It installs Java 17, Android SDK 35 and Gradle 8.9, runs `:app:assembleDebug`, verifies the APK and uploads an artifact.

Expected APK name:
`PVNetwork-VPN-v0.2-dedicated-debug.apk`

## Local
Requirements: JDK 17, Android SDK platform 35 and Gradle 8.9.

Command:
`gradle :app:assembleDebug`

## Release
Debug signing is not a production release. Production signing key material must not be committed. A later release workflow will use protected GitHub secrets and generate AAB/APK with an immutable version tag.
