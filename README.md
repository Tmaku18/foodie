# Foodie (Food Tinder) - Offline-First Flutter App

Foodie is a Flutter app that helps students choose nearby campus food using a swipe-first experience.

## Core User Flow

- Swipe right to match a restaurant (saved to SQLite).
- Swipe left to skip for the current app session.
- Tap a card to open details, menu, and notes.
- Open Basket to remove matches or clear all with animation.

## Non-Negotiable Scope

- Offline-only architecture (no cloud backend, no external restaurant APIs).
- Local persistence with SQLite for app entities and `SharedPreferences` for settings.
- BLoC/Cubit state management with `get_it` dependency injection.
- Walking-radius filtering based on seeded distance data (no GPS permission).

## Run Locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Preload Google Places Into Packaged Seed

The app can ship with Google Places restaurants already bundled into the package (instead of only demo seed rows).  
This is done by generating `lib/data/seed/generated_google_places_seed.dart` before running the app.

### 1) Set up Google Places API key (one-time)

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project (or select an existing one).
3. Link a billing account to that project.
4. Open **APIs & Services > Library** and enable **Places API (New)**.
5. Open **APIs & Services > Credentials** and click **Create credentials > API key**.
6. Restrict the key:
   - **Application restrictions**: for local scripting, start with unrestricted or IP restricted as needed.
   - **API restrictions**: select **Restrict key** and allow only **Places API (New)**.
7. Save the key securely (do not commit it into git).

### 2) Run preload script before app run

PowerShell:

```bash
$env:GOOGLE_MAPS_API_KEY="your_api_key_here"
dart run tool/preload_google_places_seed.dart
```

Optional flags:

```bash
dart run tool/preload_google_places_seed.dart --max-results=20 --out=lib/data/seed/generated_google_places_seed.dart
```

### 3) Run app normally

```bash
flutter run
```

On first launch, `ensureSeeded()` uses generated Google Places seed if present; otherwise it falls back to demo seed data.

### 4) Optional in-app refresh flow

You can still refresh from Google at runtime:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_api_key
```

Then:
- Open `Settings`
- Tap `Refresh from Google Places`

Notes:
- Runtime remains local-first after import.
- If an API call fails, existing local SQLite data is preserved.

## Repository Workflow

`foodie-atomic-main` is the default mainline branch for this repository.

## Project Structure

- `lib/app/`: app shell and top-level navigation.
- `lib/core/`: db, DI, settings, and local services.
- `lib/data/`: local repository + seed data.
- `lib/domain/`: repository contracts.
- `lib/features/`: onboarding, discover, details, basket, settings.
- `test/`: unit and widget tests.
- `integration_test/`: end-to-end flows.

## Documentation

- `REQUIREMENTS.md`: rubric-aligned requirements.
- `docs/REQUIREMENTS_COMPLIANCE_MATRIX.md`: requirement status and evidence.
- `docs/FLUTTER_STEP_BY_STEP_IMPLEMENTATION.md`: beginner walkthrough.
- `docs/MILESTONE_VERIFICATION_GATES.md`: acceptance gates by phase.

