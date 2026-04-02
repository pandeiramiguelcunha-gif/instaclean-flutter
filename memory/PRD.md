# InstaClean PMC - Product Requirements Document

## Original Problem Statement
Flutter mobile app "InstaClean PMC" - a phone cleaner that finds and deletes duplicate files (photos, videos, screenshots). Monetized with Google AdMob, tracked with Firebase Analytics, built via Codemagic CI/CD, targeting Google Play Store release.

## User Personas
- Android users in Portuguese-speaking countries (Angola, Portugal, Brazil)
- Non-technical users wanting to free storage space

## Core Requirements
1. Dark-themed professional UI with dashboard gauge, permission flow, results, and category detail screens
2. Real file scanning using `photo_manager` to find duplicates by hash comparison
3. Categories: Photos, Screenshots, Videos (Music REMOVED as of Feb 2026)
4. Screenshots: STRICT filter - only `.png`/`.jpg` from paths containing "Screenshots"
5. Google AdMob (Banner + Interstitial) with UMP/GDPR consent
6. Firebase Analytics tracking scan and cleaning events
7. Codemagic CI/CD producing signed `.aab` for Play Store

## What's Been Implemented (Completed)
- [x] Codemagic CI/CD pipeline with signed `.aab` builds
- [x] Dark theme UI: Permission, Dashboard, Results, CategoryDetail, Settings, PrivacyPolicy screens
- [x] Real file scanning engine with `photo_manager` + `crypto` hash dedup
- [x] AdMob integration (Banner + Interstitial) with real Ad Unit IDs
- [x] UMP SDK (GDPR consent form) before ad loading
- [x] Firebase Analytics (`scan_iniciado`, `scan_concluido`, `limpeza_concluida`, `permissao_concedida`)
- [x] Professional app icon via `flutter_launcher_icons`
- [x] R8/ProGuard rules for release build
- [x] Keystore (`.jks`) created for release signing
- [x] Privacy Policy + `app-ads.txt` hosted on GitHub Pages
- [x] Google Play Console setup guidance (Data Safety, App Content, etc.)
- [x] **Strict screenshot filtering** - only `.png`/`.jpg` from `/Screenshots/` path (Feb 2026)
- [x] **Music feature completely removed** - enum, logic, UI, Android permissions (Feb 2026)
- [x] **READ_MEDIA_AUDIO permission removed** from AndroidManifest.xml (Feb 2026)

## AdMob Configuration
- App ID: `ca-app-pub-2353019524746156~7848109235`
- Banner Ad Unit: `ca-app-pub-2353019524746156/4464707500`
- Interstitial Ad Unit: `ca-app-pub-2353019524746156/9525462496`
- Publisher ID: `pub-2353019524746156`

## Prioritized Backlog
### P1
- [ ] Verify AdMob 0% match rate issue (user needs to verify identity/PIN in AdMob console)
- [ ] Guide user on Angola region selection in Play Console

### P2
- [ ] Complete 14-day closed testing period on Play Console
- [ ] Promote from closed testing to production release

### Future
- [ ] User provides real `google-services.json` from Firebase (currently configured)
- [ ] Monitor ad revenue and optimize ad placement

## Tech Stack
- Flutter/Dart
- `photo_manager` v3.x, `google_mobile_ads` v4.0.0, `firebase_core`, `firebase_analytics`, `crypto`
- Android Gradle Plugin 8.9.1, Gradle 8.12
- Codemagic CI/CD
- Package ID: `com.instaclean.pmc`
