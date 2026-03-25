# InstaClean PMC - Product Requirements Document

## Original Problem Statement
Build a Flutter mobile application called "InstaClean PMC" - a phone storage cleaner that scans for duplicate files (photos, videos, screenshots, music) and allows users to delete them. The app must have a professional dark-themed UI, real file access using `photo_manager`, AdMob monetization, Firebase analytics, and be configured for Google Play Store release via Codemagic CI/CD.

## User Personas
- Android users who want to free up storage by removing duplicate files
- Target market: Portuguese-speaking users (app UI in Portuguese)

## Core Requirements
1. **Permissions Flow**: Request file access permissions from the user
2. **Dashboard**: Main screen with storage gauge and scan button
3. **File Scanning**: Scan device for photos, videos, screenshots, music
4. **Duplicate Detection**: Identify duplicates via hash comparison (grouped by file size, then thumbnail hash)
5. **Category Detail View**: Grid view for each category with manual file selection
6. **File Deletion**: Delete selected files from device using `PhotoManager.editor.deleteWithIds()`
7. **Branding**: App name "InstaClean PMC" with PMC branding
8. **AdMob**: Banner and interstitial ads (currently using test IDs)
9. **Firebase Analytics**: Integration placeholder (requires user's `google-services.json`)
10. **Release Build**: AAB format signed for Google Play Store

## Tech Stack
- **Framework**: Flutter (Dart)
- **CI/CD**: Codemagic
- **Build System**: Android Gradle (AGP 8.7.0, Gradle 8.9, Kotlin 2.1.0)
- **Key Packages**: `photo_manager ^3.0.0`, `google_mobile_ads ^4.0.0`, `permission_handler ^11.3.0`, `crypto ^3.0.3`
- **Android Config**: compileSdk 36, targetSdk 35, minSdk 24, package `com.instaclean.pmc`

## Architecture
```
/app/
├── android/              # Native Android project
├── lib/
│   ├── main.dart         # App entry point, theme, routing
│   ├── screens/
│   │   ├── permission_screen.dart     # Permission request + UMP consent
│   │   ├── dashboard_screen.dart      # Main screen with gauge + settings
│   │   ├── results_screen.dart        # Cleaning categories
│   │   ├── category_detail_screen.dart # File grid with selection/deletion
│   │   ├── settings_screen.dart       # App settings
│   │   └── privacy_policy_screen.dart # GDPR/RGPD privacy policy
│   └── services/
│       ├── cleaner_service.dart       # Core scan & clean logic
│       ├── ad_service.dart            # AdMob + UMP/GDPR consent
│       └── analytics_service.dart     # Firebase Analytics events
├── assets/
│   └── app_icon.png      # App launcher icon
├── pubspec.yaml          # Dependencies
└── codemagic.yaml        # CI/CD config
```

## What's Been Implemented
- [x] Complete dark-themed UI (permission, dashboard, results, category detail screens)
- [x] Real file scanning engine using `photo_manager`
- [x] Duplicate detection (size-based grouping + thumbnail hash comparison)
- [x] File deletion functionality via `PhotoManager.editor.deleteWithIds()`
- [x] Category views: Photos, Screenshots, Videos, Music
- [x] Manual file selection with grid view and thumbnails
- [x] Branding: "InstaClean PMC"
- [x] AdMob integration (real IDs - ca-app-pub-2353019524746156)
- [x] Firebase Analytics with `limpeza_concluida` event tracking
- [x] URL launcher for external privacy policy link
- [x] Settings screen (Privacy Policy, Consent, Permissions)
- [x] Custom app icon (blue shield + white broom) via flutter_launcher_icons
- [x] Release signing config (Codemagic env vars + key.properties)
- [x] ProGuard rules for release build
- [x] Codemagic CI/CD pipeline (AAB + APK builds)
- [x] Android native project structure (compileSdk 36, AGP 8.7.0)

## Pending Items
- [ ] **P1**: Configure keystore in Codemagic (upload keystore + set env vars)
- [ ] **P2**: Google Play Store publication (after signed AAB is built)

## Current Status
- **Build Status**: Production-ready configuration
- **Mocked**: None - All integrations use real credentials
