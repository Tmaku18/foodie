import 'dart:math';

import 'package:foodie/domain/repositories/food_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundPicksService {
  static const _key = 'todays_picks';

  Future<void> prepareTodaysPicks(List<int> restaurantIds) async {
    final prefs = await SharedPreferences.getInstance();
    final shuffled = [...restaurantIds]..shuffle(Random());
    final picks = shuffled.take(3).map((id) => id.toString()).toList();
    await prefs.setStringList(_key, picks);
  }

  Future<List<int>> getTodaysPicks() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).map(int.parse).toList(growable: false);
  }

  Future<void> runCycle(FoodRepository repository) async {
    final ids = (await repository.getRestaurants()).map((e) => e.id).toList(growable: false);
    await prepareTodaysPicks(ids);
  }
}
