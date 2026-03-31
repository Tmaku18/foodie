# Milestone Verification Gates

Use these gates to decide if a milestone is complete before moving forward.

## Gate A: Repo and Baseline Integrity

- Local branch matches `origin/foodie-main`.
- Working tree clean.
- `.cursor/` ignored by git.
- Build tooling available and app boots.

## Gate B: Data Foundation

- SQLite schema created with required tables.
- Seed data loads without network.
- SharedPreferences settings persist across restart.
- No cloud or external API dependencies introduced.

## Gate C: Core UX

- Discover swipe deck works smoothly.
- Right swipe persists basket match.
- Left swipe skips for session.
- Card tap navigates to details.
- Details screen loads menu and notes.

## Gate D: CRUD and Basket Behavior

- Create note/review persists.
- Read behavior confirmed on discover/details/basket.
- Update note/review works.
- Delete one basket item works.
- Empty Basket clears all matches and shows explicit animation.

## Gate E: Walking Radius Rules

- Default walking radius is 2 miles.
- Radius can be changed in settings.
- No GPS permissions requested.
- Distance and walk time displayed.
- Empty-state shown when no restaurants in radius.

## Gate F: Architecture and State Compliance

- Data/Domain/Presentation boundaries respected.
- Repositories defined in domain, implemented in data.
- Cubits manage state transitions.
- `get_it` DI wiring used for app services.

## Gate G: Advanced Features

- Background process generates local \"Today's Picks\" output.
- Local notifications trigger reminder.
- Export to JSON/CSV writes files to app documents directory.

## Gate H: Test Evidence

- At least 10 unit tests pass.
- Required widget tests pass.
- Required integration test passes.
- Coverage generated with `flutter test --coverage`.

## Gate I: Documentation Complete

- `README.md` updated with setup, usage, architecture, testing, and known issues.
- `ARCHITECTURE.md` explains design and state management rationale.
- `docs/PROJECT_REPORT.md` documents outcomes and challenges.
- Compliance matrix updated with current status.

## Gate J: Version Control Discipline

For each completed milestone:
- Commit uses meaningful message with intent.
- Commit pushed to remote immediately.
- History clearly reflects incremental progress.
