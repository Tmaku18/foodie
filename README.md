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

