import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:foodie/core/services/file_export_service.dart';
import 'package:foodie/features/basket/presentation/cubit/basket_cubit.dart';
import 'package:foodie/features/basket/presentation/pages/basket_page.dart';

import '../support/fake_food_repository.dart';

void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<FileExportService>()) {
      getIt.registerLazySingleton<FileExportService>(FileExportService.new);
    }
  });

  testWidgets('shows empty state when basket has no matches', (tester) async {
    final repo = FakeFoodRepository();
    final basketCubit = BasketCubit(repo);
    await basketCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: basketCubit,
          child: const BasketPage(),
        ),
      ),
    );

    expect(find.text('No matches yet'), findsOneWidget);
  });

  testWidgets('shows list when matches exist', (tester) async {
    final repo = FakeFoodRepository();
    await repo.addBasketMatch(1);
    final basketCubit = BasketCubit(repo);
    await basketCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: basketCubit,
          child: const BasketPage(),
        ),
      ),
    );

    expect(find.textContaining('Restaurant #1'), findsOneWidget);
  });
}
