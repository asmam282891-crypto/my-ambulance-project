---
name: Flutter APK build environment
description: Local Android build setup and compatibility constraints for Flutter projects in this workspace.
---

Flutter projects may arrive as Dart source without generated Android scaffolding. The Android project can be generated with Flutter, but the build requires a locally installed Flutter SDK, Android command-line tools, an Android platform matching plugin requirements, and Java 17 for reliable Gradle/JDK image transforms.

**Why:** The workspace does not provide Flutter as a built-in module, and newer camera/location dependencies may require Android SDK 36 while the default Java runtime can fail during Gradle transforms.

**How to apply:** Before building a Flutter APK, confirm Flutter, Android SDK, and Java 17 are available; generate Android files if absent; compile against the highest SDK required by dependencies; then use the Flutter release APK output.