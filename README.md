# Gym Tracker

Flutter app: calendar of gym days, body parts per day, streaks, stats, animations.
This is the finished result of the six step prompts (01 to 06) combined.

## Setup

```bash
flutter create --org com.gymtracker --platforms=android,ios gym_tracker
cd gym_tracker

flutter pub add flutter_riverpod sqflite path table_calendar intl dynamic_color flutter_animate google_fonts
flutter pub add --dev sqflite_common_ffi

# copy this folder's lib/ and test/ over the generated ones
# (delete the generated test/widget_test.dart, it references the counter app)

flutter pub get
flutter analyze
flutter test
flutter run
```

`flutter test` runs the streak tests and the database tests (the latter use
`sqflite_common_ffi`, which needs the SQLite library on your desktop; on Linux:
`sudo apt install libsqlite3-dev`).

## App name

```bash
sed -i 's/android:label="[^"]*"/android:label="Gym Tracker"/' android/app/src/main/AndroidManifest.xml
# macOS only:
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Gym Tracker" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleName Gym Tracker" ios/Runner/Info.plist
```

## Release

```bash
flutter run --release
flutter build apk --release
flutter build appbundle --release   # Play Store
flutter build ipa --release         # iOS, needs macOS and signing
```

## Structure

```
lib/
  main.dart, app.dart          ProviderScope, themes (Material You + seed fallback)
  models/                      BodyPart, WorkoutDay
  logic/                       date_utils, streak_logic (pure Dart)
  db/database_helper.dart      sqflite, foreign keys, transactions
  providers/providers.dart     Riverpod providers (optimistic writes)
  screens/                     home_shell, calendar_screen, stats_screen
  widgets/                     day_sheet, body_part_chips, stat_card, streak_badge,
                               motion helpers, sparkle_burst
test/                          streak_test, database_test
```

## Notes

- Fonts: `google_fonts` downloads Nunito at first run and caches it. To work fully
  offline from the first launch, bundle the font files as assets.
- Material 3 Expressive: written on stable Material 3 with the expressive feel
  (28dp shapes, heavy numerals, tonal surfaces). Swap in Expressive components
  later if your SDK ships them.
- The optional adaptive icon was skipped; use `flutter_launcher_icons` when you
  have artwork.
