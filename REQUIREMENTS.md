# Foodie (Offline-First) 
## What I’m building (quickly)

**Foodie** is a “Tinder for Food” Flutter app for students: I show restaurant cards one at a time, and the user **swipes right** to match (save it) or **swipes left** to skip it (for the current session). Matches go into an **Empty Basket** screen and are saved locally so they persist across app restarts.

## Non‑negotiables (rule compliance)

- **No cloud**: I will not use Firebase, Supabase, or any cloud database/storage.
- **No external restaurant APIs**: I will not call Google Places, Yelp, etc. Ratings are **mock/demo values** stored locally.
- **Offline-first**: The app works in airplane mode. Images are bundled as local assets (no network images).
- **Persistence choices**:
  - **SQLite (`sqflite`)** for app data (restaurants, menu, matches, reviews).
  - **SharedPreferences** only for settings (theme/units/notification toggle).

## Screens (minimum 5 distinct pages)

I will implement **at least** these screens:

- **Onboarding / Welcome**: quick “how it works” + offline-first note + how to swipe.
- **Discover**: swipe deck (core experience).
- **Restaurant Details**: menu + ratings + links + notes/reviews.
- **Basket**: saved matches from SQLite + “Empty Basket” button.
- **Settings**: dark mode toggle (bonus), units toggle (mi/km) or travel mode (walk/drive estimate), notifications toggle.

## Navigation & responsive design

- **Navigation**: BottomNavigationBar for Discover/Basket/Settings, with Details pushed from Discover/Basket.
- **Responsive**: layouts must work in both **portrait and landscape** (no broken overflow UI).

## Data persistence requirements (SQLite + CRUD)

### Database tables (planned)

- **restaurants** (seeded locally)
- **menu_items** (linked to restaurants)
- **basket_matches** (linked to restaurants; stores timestamps)
- **reviews_or_notes** (linked to restaurants; editable)

### CRUD evidence (required)

- **Create**:
  - Swipe-right creates a row in `basket_matches`.
  - Adding a note/review creates a row in `reviews_or_notes`.
- **Read**:
  - Discover reads restaurant seed data.
  - Details reads menu + ratings + reviews.
  - Basket reads matched restaurants.
- **Update**:
  - User can edit a saved note/review.
- **Delete**:
  - User can delete a single basket entry.
  - “Empty Basket” deletes **all** matches from SQLite.

## On-campus “walking distance” requirements (no GPS)

- **No device location**: I will not request or use GPS/location permissions.
- **Walking distance filter**: only show restaurants considered “on campus” / within a fixed walking radius.
  - Implementation approach: store each restaurant’s distance-from-campus-center (or coordinates relative to a campus center) as local seed data, then filter by a user-selectable walking radius in Settings.
- **Default radius**: I will treat **2 miles** as the default “walking distance” radius (and let the user reduce it in Settings).
- **Distance / walk time display**:
  - Show an approximate distance (mi/km) and a walk-time estimate using a simple constant walking speed.
- **Empty state**: if no restaurants are within the selected radius, show a clear message and let the user adjust the radius.

## Swipe + card UI requirements

- **Swipe deck**: smooth, high-performance card stack.
- **Card content**:
  - First image: restaurant building/exterior.
  - Subsequent images: food images in an **auto-advancing carousel**.
- **Gestures**:
  - Swipe right → match + persist.
  - Swipe left → discard for session.
  - Tap → details page.

## UI/UX quality requirements

- **Material Design**: consistent theme and visual system (Material 3).
- **Animations**:
  - Smooth card transitions.
  - **Explicit animation** for “Empty Basket” clearing action.
  - Include at least one implicit animation as well.
- **Accessibility**:
  - Semantics labels for important actions (swipe, buttons, links).
  - Tap targets that aren’t tiny.
  - Respect text scaling.
- **Empty/loading/error states**:
  - No restaurants available in current walking radius
  - No restaurants available
  - Empty basket

## Graduate architecture requirements (how I’ll implement)

- **Clean Architecture**: clear separation of **Data / Domain / Presentation**.
- **Repository pattern**: Domain defines interfaces; Data implements them using SQLite.
- **Dependency Injection**: `get_it` wires DB, repositories, services, and Cubits.
- **State management**: **BLoC with Cubit (`flutter_bloc`)**
  - Cubits manage feature states; UI reacts via BlocBuilder/BlocListener/BlocSelector.
  - Business rules live in Domain use cases, not widget code.

### Why BLoC (and why not Provider or Riverpod?)

The project guide allows **Provider**, **Riverpod**, or **BLoC**. I’m using **BLoC with Cubit** for these reasons, in plain English:

**Why BLoC fits this project**

- **Clear split between UI and logic.** The screen only shows state and calls methods (e.g. “load basket”, “empty basket”). All real logic lives in Cubits and use cases, so it’s easy to explain in ARCHITECTURE.md and in the demo: “UI talks to Cubit, Cubit talks to use cases, use cases talk to repositories.”
- **Works naturally with Clean Architecture.** We have Data / Domain / Presentation. BLoC/Cubit sits in Presentation and only uses Domain (use cases). It never touches SQLite or SharedPreferences directly, so the dependency rule stays clean.
- **Easier to test.** The rubric asks for unit tests (10+) and widget tests. With BLoC, I can test “swipe right saves to basket” and “empty basket deletes all” by testing the Cubit and use cases alone, without building the full UI. Then I test the widgets separately. That keeps tests fast and focused.
- **Predictable updates.** State is immutable and emitted in a stream. The UI listens with BlocBuilder/BlocListener. There’s one clear place for “what is the current state?” and no setState scattered around, which helps when we add things like radius filters or notifications.
- **Cubit vs full Bloc.** For most screens we don’t need a full event stream (tap → event → new state). Simple actions like “load basket” or “delete item” are just method calls. Cubit (methods that emit new state) keeps the code smaller while still giving the same testability and separation.

**Why not Provider?**

- Provider is quick to set up and good for small apps, but the logic often ends up mixed with the UI or inside ChangeNotifier. For a graduate project we need a clear “business logic layer” that we can point to and test. BLoC keeps that layer explicit (Cubits + use cases) and makes it obvious where the rules live. With Provider it’s easier to slip into putting logic in widgets or one big notifier, which is harder to test and to document in ARCHITECTURE.md.

**Why not Riverpod?**

- Riverpod is strong and testable, and doesn’t depend on BuildContext. For this project, BLoC was chosen because (1) the rubric explicitly lists “BLoC” and it’s a common interview/portfolio talking point, (2) the event/state model (or Cubit’s method → state) is easy to draw and explain in a report, and (3) the team is already aligned on Clean Architecture with use cases—Cubits “orchestrate” use cases in a way that’s easy to describe. Riverpod would work too, but BLoC gives a simple, defensible story for “why this pattern” in the write-up and presentation.

**Bottom line:** BLoC (with Cubit) gives a clear, testable split between UI and logic, fits Clean Architecture, and makes it straightforward to meet the graduate state-management requirement and to explain the choice in the report and demo.

## Graduate advanced features (explicitly required)

- **Background processing**: schedule a background task that prepares “Today’s Picks” using local data.
- **Local notifications**: send a reminder notification like “Top match to try today.”
- **File system operations**: export basket/reviews to JSON/CSV in the app documents directory (import optional).

## Testing requirements (graduate)

- **Unit tests (minimum 10)**: focus on domain use cases + Cubits (business logic).
- **Widget tests**: at least the main swipe interface + basket behavior.
- **Integration test(s)**: swipe-right persists → appears in basket after restart flow.
- **Coverage report**: include instructions for `flutter test --coverage`.

## Documentation deliverables (I will produce)

- **Project proposal**: `Project1_Proposal_Foodie_Tanaka_Makuvaza.doc`
- **README.md**: setup steps, usage guide, features, dependencies, DB schema, known issues, future work, license.
- **ARCHITECTURE.md**: why BLoC/Cubit, repository pattern flow, DI wiring, persistence story.
- **Project report**: `docs/PROJECT_REPORT.md` (or equivalent) describing features, challenges, solutions.

## Version control expectations (rubric alignment)

- **Steady commit history**: I will commit regularly with meaningful messages (goal: 20+ commits per contributor).
- **Branches + PRs**: features developed on branches and merged via pull requests (even if the team is small, this shows workflow discipline).
- **Milestone evidence**: repo history should clearly show progress by feature milestone (DB → swipe → basket → settings → notifications/export → tests/docs).
