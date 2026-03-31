# Flutter Step-by-Step Implementation Walkthrough (Beginner-Friendly)

This walkthrough is intentionally slow and explanatory for developers new to Flutter and Dart.

## Guiding Principles

1. Build a small slice, verify it, then move on.
2. Keep business logic out of UI widgets.
3. Prefer local/offline-first behavior at every stage.
4. Commit and push after every completed change step.

## Technology Baseline

- Flutter (Material 3 UI)
- `flutter_bloc` (Cubit pattern)
- `get_it` (dependency injection)
- `sqflite` (structured local app data)
- `shared_preferences` (simple settings only)

## Step 0: Tooling and Project Skeleton

### What to do
- Create Flutter app scaffold.
- Set up folder structure by layer/feature.
- Add required packages in `pubspec.yaml`.
- Add a minimal app shell with `MaterialApp` and route placeholders.

### Why
- In Flutter, everything is a widget. A clean shell helps us test navigation early and avoid tangled code later.

### Verify
- App launches on emulator/device.
- Can navigate to placeholder pages.

## Step 1: Clean Architecture Boundaries

### What to do
- Create `data`, `domain`, and `presentation` folders per feature.
- Define domain interfaces (repositories) before implementations.
- Add `get_it` registration entrypoint.

### Why
- Beginners often place logic directly in widgets. This makes apps hard to test.
- Boundaries force a clean separation:
  - Presentation = how it looks
  - Domain = business rules
  - Data = storage details

### Verify
- `get_it` boots successfully.
- No direct SQLite calls from widget files.

## Step 2: Local Data Layer (SQLite + Seed)

### What to do
- Create tables: `restaurants`, `menu_items`, `basket_matches`, `reviews_or_notes`.
- Add DB migration/versioning.
- Seed restaurants and menu data from local assets.

### Why
- Offline-first needs real local storage, not in-memory lists.
- `sqflite` gives SQL tables and persistence across restarts.

### Verify
- Seed rows exist after first launch.
- Data still exists after app restart.

## Step 3: Settings Persistence (SharedPreferences)

### What to do
- Add settings service for:
  - dark mode
  - units (mi/km)
  - notification toggle
  - walking radius (default 2 miles)

### Why
- `shared_preferences` is ideal for tiny key-value settings.
- We keep structured app entities in SQLite only.

### Verify
- Toggle settings, restart app, values remain.

## Step 4: Discover Screen + Swipe Core

### What to do
- Build swipe card deck UI.
- Right swipe: insert row in `basket_matches`.
- Left swipe: skip restaurant for session state.
- Tap card: open details page.

### Why
- This is the app's core interaction; implement and stabilize first.

### Verify
- Swipe right appears in Basket.
- Swipe left does not persist to Basket.
- Tap opens details consistently.

## Step 5: Details + Menu + Notes CRUD

### What to do
- Show details page with menu list and ratings.
- Add create/update/delete note flow (`reviews_or_notes`).

### Why
- Demonstrates required CRUD depth and user decision support before matching.

### Verify
- Add note, edit note, delete note all persist correctly.

## Step 6: Basket + Empty Basket Animation

### What to do
- Build Basket list from SQLite matches.
- Add single remove.
- Add Empty Basket action with explicit animation.

### Why
- Basket is a key rubric screen and must include explicit animation behavior.

### Verify
- Single remove works.
- Empty basket clears all rows and plays animation.

## Step 7: Walking Radius Logic (No GPS)

### What to do
- Use seeded distance-from-campus values.
- Filter discover list by user-selected radius.
- Display distance and walk-time estimate.
- Show clear empty-state when no matches in radius.

### Why
- Requirement explicitly forbids GPS; all radius logic is local and deterministic.

### Verify
- Lower radius filters list.
- Empty-state appears and guides user to adjust radius.

## Step 8: Advanced Graduate Features

### What to do
- Add local background processing for \"Today's Picks\".
- Add local notifications for reminders.
- Add export basket/reviews to JSON/CSV files.

### Why
- These satisfy graduate-level advanced feature requirements.

### Verify
- Background job writes expected output.
- Notification fires locally.
- Export file is created and readable.

## Step 9: Testing and Documentation

### What to do
- Add 10+ unit tests (use cases + cubits).
- Add widget tests for discover swipe and basket behavior.
- Add integration test for swipe-right persistence after restart.
- Document coverage command and run: `flutter test --coverage`.

### Why
- Tests are mandatory evidence of architecture quality and behavior correctness.

### Verify
- Test suite passes.
- Coverage artifact generated.

## Commit Discipline (Mandatory)

For every completed step:
1. Stage only relevant files.
2. Commit with a meaningful message describing intent.
3. Push immediately after successful commit.

Example message style:
- `feat(discover): add swipe-right basket persistence with cubit flow`
- `test(basket): verify empty basket clears sqlite rows`
