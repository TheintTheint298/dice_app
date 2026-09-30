# Dice (Flutter, iOS + Android)

## Structure
lib/logic  – DiceEngine (Random.secure), DiceController (state, history, prefs)
lib/ui     – HomeScreen, DieView (CustomPaint 3D die)
test/      – logic + widget tests

## Setup
1. Install Flutter 3.22+.
2. In this folder: `flutter create . --platforms=ios,android --org com.example --project-name dice_app`
   (generates ios/ and android/ without touching lib/ or pubspec.yaml)
3. Put a 1024x1024 `assets/icon.png`, then:
   `dart run flutter_launcher_icons && dart run flutter_native_splash:create`
4. `flutter pub get && flutter run`
5. `flutter test`

## Platform config
No permissions needed: shake uses the accelerometer (no prompt on iOS/Android),
sound uses system click, no network. iOS: min target 12.0 (ios/Podfile), set
your Team + Bundle ID in Xcode. Android: set applicationId and minSdk 21 in
android/app/build.gradle.

## Release
Android: create keystore (`keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`),
reference it in android/key.properties + build.gradle signingConfigs, then
`flutter build appbundle --release` (or `flutter build apk --release`).
iOS: `flutter build ipa --release`, then upload via Xcode Organizer / Transporter.
