# Mobile addon — Native (SwiftUI + Kotlin/Compose)

Two separate native codebases for iOS and Android. Recommended for products where mobile feel is a competitive differentiator (photo, video, drawing, fitness, gaming).

## What you get

- `ios/` directory with SwiftUI app scaffold, Swift Package Manager dependencies
- `android/` directory with Kotlin + Jetpack Compose scaffold, Gradle build
- Shared API spec via OpenAPI (see `addons/openapi-clients` for client generation)
- `make ios-test`, `make ios-lint`, `make android-test`, `make android-lint` targets
- CI workflows `.github/workflows/ios.yml` and `android.yml`

## When to use

- Premium product where UI quality matters
- Heavy media (photos, video, audio)
- Native sensor / hardware integration is core to the feature
- You're willing to maintain two codebases

## When NOT to use

- Solo dev with no mobile experience and tight timeline
- App is mostly forms and lists
- API-first product where the UI is a thin shell

## Apply

```bash
# Drop addons/mobile-native/ios/ into your repo as ios/
# Drop addons/mobile-native/android/ into your repo as android/
cp -r addons/mobile-native/ios .
cp -r addons/mobile-native/android .

# Open ios/MyApp.xcodeproj in Xcode to set bundle ID
# Open android/ in Android Studio to sync Gradle
```

## Files

```
addons/mobile-native/
├── README.md
├── ios/
│   ├── README.md
│   ├── Package.swift
│   └── Sources/
└── android/
    ├── README.md
    ├── settings.gradle.kts
    ├── build.gradle.kts
    └── app/
```

Add to CLAUDE.md when adopting:

```
## Mobile invariants
- iOS uses SwiftUI + async/await. No UIKit unless wrapping a non-SwiftUI library.
- Android uses Compose + Kotlin coroutines. No Views/XML.
- API DTOs are generated from OpenAPI spec — never hand-written.
- Both apps target the same minimum API contract. Differences in UX are OK; differences in data flow are not.
```
