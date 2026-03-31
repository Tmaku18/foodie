import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie/features/basket/presentation/cubit/basket_cubit.dart';
import 'package:foodie/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:foodie/features/discover/presentation/pages/discover_page.dart';
import 'package:foodie/features/settings/presentation/cubit/settings_cubit.dart';

import '../support/fake_food_repository.dart';
import '../support/fake_preferences_service.dart';

void main() {
  testWidgets('shows no results message when nothing in radius', (tester) async {
    final repo = FakeFoodRepository();
    final discoverCubit = DiscoverCubit(repo);
    await discoverCubit.load();
    discoverCubit.applyRadius(0.1);

    final settingsCubit = SettingsCubit(FakePreferencesService());
    await settingsCubit.load();
    final basketCubit = BasketCubit(repo);
    await basketCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: settingsCubit),
            BlocProvider.value(value: discoverCubit),
            BlocProvider.value(value: basketCubit),
          ],
          child: const DiscoverPage(),
        ),
      ),
    );

    expect(find.textContaining('No restaurants available in the current walking radius'), findsOneWidget);
  });
}
