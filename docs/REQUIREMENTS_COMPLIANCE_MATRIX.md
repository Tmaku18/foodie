# Foodie Requirements Compliance Matrix

This matrix maps each requirement in `REQUIREMENTS.md` to implementation targets and verification evidence.

## 1) Non-Negotiables

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| No cloud services | `lib/` architecture uses only local services; no Firebase/Supabase packages in `pubspec.yaml` | Dependency review + offline run in airplane mode |
| No external restaurant APIs | Local seed files under `assets/data/` + SQLite seed job in `lib/data/local/seed/` | Network-disabled testing, no HTTP clients in data layer |
| Offline-first | All app data read/write via SQLite/shared_preferences | App usable after restart with network off |
| SQLite for app data | `lib/data/local/db/app_database.dart` + repositories in `lib/data/repositories/` | CRUD tests + integration flow |
| SharedPreferences only for settings | `lib/core/settings/preferences_service.dart` | Settings persist after restart |

## 2) Screens and Navigation

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| Onboarding/Welcome | `lib/features/onboarding/presentation/pages/onboarding_page.dart` | Manual launch path and completion state |
| Discover (swipe deck) | `lib/features/discover/presentation/pages/discover_page.dart` | Swipe UX test |
| Restaurant Details | `lib/features/details/presentation/pages/details_page.dart` | Tap card -> details route |
| Basket | `lib/features/basket/presentation/pages/basket_page.dart` | Saved matches shown |
| Settings | `lib/features/settings/presentation/pages/settings_page.dart` | Preference changes persist |
| BottomNavigationBar + push details | `lib/app/navigation/main_shell.dart` + route config in `lib/app/router/app_router.dart` | Route integration test |
| Portrait + landscape support | Responsive layouts in feature page widgets | Golden/widget tests on multiple sizes |

## 3) SQLite Tables and CRUD Evidence

| Table/Behavior | Implementation Target | Verification Evidence |
|---|---|---|
| restaurants | `lib/data/local/db/schema/restaurants_table.dart` | Seed + read query |
| menu_items | `lib/data/local/db/schema/menu_items_table.dart` | Details menu load |
| basket_matches | `lib/data/local/db/schema/basket_matches_table.dart` | Swipe-right inserts row |
| reviews_or_notes | `lib/data/local/db/schema/reviews_notes_table.dart` | Create/update/delete note tests |
| Create | Cubit action -> use case -> repository insert | Unit tests |
| Read | Discover/details/basket read repositories | Widget/integration tests |
| Update | Edit review/note flow | Unit + widget test |
| Delete | Single basket remove + empty basket bulk delete | Unit + widget test |

## 4) On-Campus Walking Constraints (No GPS)

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| No GPS permissions | No location plugin, no runtime permission requests | Android/iOS permission manifest review |
| Radius-based walking filter | `lib/features/settings/domain/entities/walking_radius.dart` + discover filtering use case | Radius change updates candidate list |
| Default radius = 2 miles | Default in settings seed/service | Startup behavior check |
| Distance + walk time display | Calculated in `lib/features/discover/domain/services/walk_time_estimator.dart` | UI labels + unit tests |
| Empty state when none in radius | Discover empty-state component | Widget test |

## 5) Swipe Card UX

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| Smooth swipe deck | Gesture-driven card stack under discover presentation layer | Manual performance check + widget behavior |
| Building image first | Card media ordering in card view model | UI inspection |
| Auto-advancing food carousel | Carousel widget with timer and pause/resume hooks | Widget test for index advance |
| Right swipe saves | Discover cubit/use case to insert basket match | Unit test |
| Left swipe skips session | In-memory session skip set in discover state | Session behavior test |
| Tap opens details | Router push from card tap | Navigation test |

## 6) UI/UX Quality

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| Material 3 | App theme in `lib/app/theme/` | Visual review |
| Explicit animation for Empty Basket | Basket clear animation controller | Widget test with animation state |
| At least one implicit animation | Animated container/switcher in discover/settings | Widget test |
| Accessibility semantics | Semantics labels on card actions and controls | Semantics tester |
| Text scaling support | Scalable text styles + no overflow layouts | Large text test |
| Empty/loading/error states | Shared state widgets in `lib/core/ui/states/` | Widget tests |

## 7) Graduate Architecture + State + DI

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| Clean Architecture | `lib/data`, `lib/domain`, `lib/presentation` boundaries by feature | Architecture doc + code review |
| Repository pattern | Domain interfaces + data implementations | Unit tests against mocks/fakes |
| get_it DI | `lib/core/di/injection.dart` | App boot registration tests |
| BLoC/Cubit | Feature cubits + immutable states | Cubit unit tests |

## 8) Advanced Features

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| Background processing | Scheduled local job in `lib/features/recommendations/background/` | Manual trigger + persisted result |
| Local notifications | Notification service under `lib/core/notifications/` | Device notification test |
| File export JSON/CSV | Export service in `lib/core/files/export_service.dart` | Generated file existence + content check |

## 9) Testing Requirements

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| 10+ unit tests | `test/unit/` | `flutter test` output |
| Widget tests | `test/widget/` | Swipe + basket widget tests |
| Integration tests | `integration_test/` | Persist-after-restart path |
| Coverage command | README instructions | `flutter test --coverage` output |

## 10) Documentation Deliverables

| Requirement | Implementation Target | Verification Evidence |
|---|---|---|
| Proposal document | Existing `Project1_Proposal_Foodie_Tanaka_Makuvaza.doc` | File presence |
| README | `README.md` expanded sections | Checklist review |
| ARCHITECTURE.md | `ARCHITECTURE.md` with flow and rationale | File review |
| Project report | `docs/PROJECT_REPORT.md` | File review |

## Status Legend

- `Planned`: defined in implementation plan, not coded yet.
- `In Progress`: actively being implemented.
- `Done`: implemented and verified.
