import 'package:foodie/core/models.dart';

abstract class FoodRepository {
  Future<List<Restaurant>> getRestaurants();
  Future<List<MenuItem>> getMenuByRestaurant(int restaurantId);
  Future<void> addBasketMatch(int restaurantId);
  Future<void> removeBasketMatch(int matchId);
  Future<void> clearBasket();
  Future<List<BasketMatch>> getBasketMatches();
  Future<void> upsertNote(int restaurantId, String text);
  Future<void> deleteNote(int noteId);
  Future<List<ReviewNote>> getNotes(int restaurantId);
}
