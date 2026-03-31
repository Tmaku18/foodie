import 'package:flutter_test/flutter_test.dart';
import 'package:foodie/features/basket/presentation/cubit/basket_cubit.dart';
import '../support/fake_food_repository.dart';

void main() {
  group('BasketCubit', () {
    test('load reads basket matches', () async {
      final repo = FakeFoodRepository();
      await repo.addBasketMatch(1);
      final cubit = BasketCubit(repo);

      await cubit.load();

      expect(cubit.state.matches.length, 1);
    });

    test('removeMatch deletes single item', () async {
      final repo = FakeFoodRepository();
      await repo.addBasketMatch(1);
      final id = repo.basket.first.id;
      final cubit = BasketCubit(repo);
      await cubit.load();

      await cubit.removeMatch(id);

      expect(cubit.state.matches, isEmpty);
    });

    test('emptyBasket removes all', () async {
      final repo = FakeFoodRepository();
      await repo.addBasketMatch(1);
      await repo.addBasketMatch(2);
      final cubit = BasketCubit(repo);
      await cubit.load();

      await cubit.emptyBasket();

      expect(cubit.state.matches, isEmpty);
    });
  });
}
