# Foodie Requirements Compliance Matrix

Status values:
- `Planned`
- `In Progress`
- `Verified`

| Requirement Area | Status | Implementation | Evidence |
|---|---|---|---|
| Offline runtime with optional Google import | Verified | App reads from local SQLite at runtime; optional Settings-triggered Places import upserts local DB | `lib/data/import/google_places_import_service.dart` + runtime behavior after import |
| SQLite app data (`restaurants`, `menu_items`, `basket_matches`, `reviews_or_notes`) | Verified | `lib/core/db/app_database.dart` and `lib/data/repositories/local_food_repository.dart` | Runtime behavior in discover/details/basket |
| SharedPreferences for settings only | Verified | `lib/core/settings/preferences_service.dart` | `test/unit/settings_cubit_test.dart` |
| Onboarding screen | Verified | `lib/features/onboarding/presentation/pages/onboarding_page.dart` | first-run gating in `lib/app/app_root.dart` |
| Discover swipe flow | Verified | `lib/features/discover/presentation/pages/discover_page.dart` | `test/unit/discover_cubit_test.dart` + `test/widget/discover_page_test.dart` |
| Details screen and notes CRUD | Verified | `lib/features/details/presentation/pages/details_page.dart` | manual path + repository CRUD |
| Basket screen + clear behavior | Verified | `lib/features/basket/presentation/pages/basket_page.dart` | `test/unit/basket_cubit_test.dart`, `test/widget/basket_page_test.dart` |
| Settings screen (radius, units, toggles) | Verified | `lib/features/settings/presentation/pages/settings_page.dart` | `test/unit/settings_cubit_test.dart` |
| Walking radius with no GPS | Verified | local distance values + radius filter; no location permissions requested | discover empty-state + filtering behavior |
| Card media ordering and carousel | Verified | building image first + food carousel in `restaurant_card.dart` | UI structure inspection |
| Material 3 and animation requirements | In Progress | Material 3 theme enabled; implicit animation with `AnimatedSwitcher` in basket | explicit empty-basket animation can be expanded |
| Clean architecture + repository pattern + DI + Cubit | Verified | layer separation + `get_it` + cubits | `ARCHITECTURE.md` + code layout |
| Advanced: background processing | Verified | `lib/core/services/advanced_features_coordinator.dart` and picks service | settings trigger + periodic cycle start |
| Advanced: local notifications | Verified | `lib/core/services/local_notification_service.dart` | settings action sends reminder |
| Advanced: JSON/CSV export | Verified | `lib/core/services/file_export_service.dart` + basket export action | export snackbar path |
| Testing: 10+ unit tests | Verified | `test/unit/` suite | `flutter test` output |
| Testing: widget tests | Verified | `test/widget/` | `flutter test` output |
| Testing: integration test | Verified | `integration_test/swipe_persistence_test.dart` | local persistence restart simulation |
| Docs: README + ARCHITECTURE + project report | Verified | `README.md`, `ARCHITECTURE.md`, `docs/PROJECT_REPORT.md` | document existence and content |
