import 'package:get_it/get_it.dart';
import 'package:foodie/core/db/app_database.dart';
import 'package:foodie/core/services/advanced_features_coordinator.dart';
import 'package:foodie/core/services/background_picks_service.dart';
import 'package:foodie/core/services/file_export_service.dart';
import 'package:foodie/core/services/local_notification_service.dart';
import 'package:foodie/core/settings/preferences_service.dart';
import 'package:foodie/data/import/google_places_import_service.dart';
import 'package:foodie/data/repositories/local_food_repository.dart';
import 'package:foodie/domain/repositories/food_repository.dart';
import 'package:foodie/features/basket/presentation/cubit/basket_cubit.dart';
import 'package:foodie/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:foodie/features/settings/presentation/cubit/settings_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<FoodRepository>()) return;

  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  getIt.registerLazySingleton<PreferencesService>(PreferencesService.new);
  getIt.registerLazySingleton<FileExportService>(FileExportService.new);
  getIt.registerLazySingleton<GooglePlacesImportService>(GooglePlacesImportService.new);
  getIt.registerLazySingleton<BackgroundPicksService>(BackgroundPicksService.new);
  getIt.registerLazySingleton<AdvancedFeaturesCoordinator>(
    () => AdvancedFeaturesCoordinator(getIt<BackgroundPicksService>(), getIt<FoodRepository>()),
  );
  getIt.registerLazySingleton<LocalNotificationService>(LocalNotificationService.new);
  getIt.registerLazySingleton<LocalFoodRepository>(
    () => LocalFoodRepository(getIt<AppDatabase>(), getIt<GooglePlacesImportService>()),
  );
  getIt.registerLazySingleton<FoodRepository>(() => getIt<LocalFoodRepository>());

  await getIt<LocalFoodRepository>().ensureSeeded();
  await getIt<LocalNotificationService>().init();
  await getIt<AdvancedFeaturesCoordinator>().start();

  getIt.registerFactory(() => SettingsCubit(getIt<PreferencesService>()));
  getIt.registerFactory(() => DiscoverCubit(getIt<FoodRepository>()));
  getIt.registerFactory(() => BasketCubit(getIt<FoodRepository>()));
}
