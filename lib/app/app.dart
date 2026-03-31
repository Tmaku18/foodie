import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/app/app_root.dart';
import 'package:foodie/core/di/injection.dart';
import 'package:foodie/features/basket/presentation/cubit/basket_cubit.dart';
import 'package:foodie/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:foodie/features/settings/presentation/cubit/settings_cubit.dart';

class FoodieApp extends StatelessWidget {
  const FoodieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SettingsCubit>()..load()),
        BlocProvider(create: (_) => getIt<DiscoverCubit>()..load()),
        BlocProvider(create: (_) => getIt<BasketCubit>()..load()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Foodie',
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.dark),
            ),
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}
