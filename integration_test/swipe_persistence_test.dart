import 'package:flutter_test/flutter_test.dart';
import 'package:foodie/features/basket/presentation/cubit/basket_cubit.dart';
import 'package:foodie/features/discover/presentation/cubit/discover_cubit.dart';

import '../test/support/fake_food_repository.dart';

void main() {
  test('swipe-right persists to basket after cubit restart', () async {
    final repo = FakeFoodRepository();

    final discoverFirstRun = DiscoverCubit(repo);
    await discoverFirstRun.load();
    await discoverFirstRun.swipeRight(discoverFirstRun.state.visible.first);

    final basketAfterRestart = BasketCubit(repo);
    await basketAfterRestart.load();

    expect(basketAfterRestart.state.matches.length, 1);
    expect(basketAfterRestart.state.matches.first.restaurantId, 1);
  });
}
