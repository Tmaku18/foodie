# Foodie Architecture

## Layering

- **Presentation**: Widgets + Cubits in `lib/features/**/presentation`.
- **Domain**: Repository contracts in `lib/domain/repositories`.
- **Data**: Local SQLite repository and seed layer in `lib/data`.
- **Core**: Shared services (`db`, `settings`, notifications, exports, DI).

## Why This Structure

- Keeps UI free from storage concerns.
- Makes core behavior testable with fake repositories/services.
- Matches rubric requirements for clean architecture, repository pattern, and BLoC/Cubit.

## Dependency Injection

- `get_it` registrations are centralized in `lib/core/di/injection.dart`.
- App startup config:
  1. create/open SQLite DB
  2. seed restaurant/menu data on first run
  3. initialize local notifications
  4. start periodic local picks refresh cycle

## Offline Data Flows

- Discover: `DiscoverCubit -> FoodRepository -> LocalFoodRepository -> SQLite`.
- Basket: `BasketCubit -> FoodRepository -> basket_matches`.
- Notes CRUD: `DetailsPage -> FoodRepository -> reviews_or_notes`.
- Settings: `SettingsCubit -> PreferencesService -> SharedPreferences`.

## Advanced Features

- **Background processing**: `AdvancedFeaturesCoordinator` runs periodic local "Today's Picks" generation.
- **Local notifications**: `LocalNotificationService` triggers reminders on-device.
- **File export**: `FileExportService` writes JSON/CSV to app documents storage.
