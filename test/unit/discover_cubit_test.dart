import 'package:flutter_test/flutter_test.dart';
import 'package:foodie/features/discover/presentation/cubit/discover_cubit.dart';
import '../support/fake_food_repository.dart';

void main() {
  group('DiscoverCubit', () {
    test('loads restaurants', () async {
      final repo = FakeFoodRepository();
      final cubit = DiscoverCubit(repo);

      await cubit.load();

      expect(cubit.state.restaurants.length, 2);
      expect(cubit.state.visible.length, 2);
    });

    test('radius filter removes far restaurants', () async {
      final repo = FakeFoodRepository();
      final cubit = DiscoverCubit(repo);
      await cubit.load();

      cubit.applyRadius(2.0);

      expect(cubit.state.visible.length, 1);
      expect(cubit.state.visible.first.id, 1);
    });

    test('swipe right stores basket match and removes from visible', () async {
      final repo = FakeFoodRepository();
      final cubit = DiscoverCubit(repo);
      await cubit.load();

      await cubit.swipeRight(cubit.state.visible.first);

      expect(repo.basket.length, 1);
      expect(cubit.state.visible.length, 1);
    });

    test('swipe left skips for session only', () async {
      final repo = FakeFoodRepository();
      final cubit = DiscoverCubit(repo);
      await cubit.load();

      cubit.swipeLeft(cubit.state.visible.first, radiusMiles: 5.0);

      expect(cubit.state.sessionSkipped, contains(1));
      expect(cubit.state.visible.map((r) => r.id), isNot(contains(1)));
    });
  });
}
