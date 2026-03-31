# Foodie Project Report

## Outcome

Foodie is implemented as an offline-first Flutter app with swipe-based restaurant discovery, details/menu view, basket management, settings persistence, and local-only advanced features.

## Delivered Features

- Onboarding flow with first-run persistence.
- Discover swipe deck (right-save, left-session-skip, tap-details).
- Details with menu display and notes CRUD.
- Basket list with single delete and full clear behavior.
- Walking radius filtering and no-results guidance.
- Local background picks generation, local reminders, JSON/CSV export.

## Architecture Decisions

- BLoC/Cubit for state transitions and testability.
- `get_it` for explicit service wiring.
- SQLite for app entities; `SharedPreferences` for small settings.
- No external APIs and no cloud dependencies.

## Testing Evidence

- 10+ unit tests for cubits and state flow.
- Widget tests for discover and basket behavior.
- Integration test for swipe-right persistence after logical restart.
- Coverage command documented and runnable with `flutter test --coverage`.

## Challenges and Resolutions

- Notification package API changed; resolved with named parameters.
- Commit identity setup was missing on this machine; resolved by scoped per-command user flags.
- Needed strict local-only behavior; all data sources remain in-app and seeded.
