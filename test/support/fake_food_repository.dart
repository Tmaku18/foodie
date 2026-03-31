import 'package:foodie/core/models.dart';
import 'package:foodie/domain/repositories/food_repository.dart';

class FakeFoodRepository implements FoodRepository {
  final restaurants = <Restaurant>[
    const Restaurant(
      id: 1,
      name: 'A',
      category: 'Burgers',
      distanceMiles: 1.0,
      rating: 4.5,
      buildingImageAsset: 'assets/images/restaurant_building.png',
      foodImageAssets: ['assets/images/food_1.png'],
    ),
    const Restaurant(
      id: 2,
      name: 'B',
      category: 'Sushi',
      distanceMiles: 3.0,
      rating: 4.2,
      buildingImageAsset: 'assets/images/restaurant_building.png',
      foodImageAssets: ['assets/images/food_2.png'],
    ),
  ];
  final menu = <MenuItem>[
    const MenuItem(id: 1, restaurantId: 1, name: 'Burger', price: 8.5, description: 'Classic'),
    const MenuItem(id: 2, restaurantId: 2, name: 'Roll', price: 10.0, description: 'Spicy'),
  ];
  final basket = <BasketMatch>[];
  final notes = <ReviewNote>[];
  int _nextBasketId = 1;
  int _nextNoteId = 1;

  @override
  Future<void> addBasketMatch(int restaurantId) async {
    basket.add(BasketMatch(id: _nextBasketId++, restaurantId: restaurantId, createdAt: DateTime.now()));
  }

  @override
  Future<void> clearBasket() async {
    basket.clear();
  }

  @override
  Future<void> deleteNote(int noteId) async {
    notes.removeWhere((n) => n.id == noteId);
  }

  @override
  Future<List<BasketMatch>> getBasketMatches() async => List.unmodifiable(basket);

  @override
  Future<List<MenuItem>> getMenuByRestaurant(int restaurantId) async {
    return menu.where((item) => item.restaurantId == restaurantId).toList(growable: false);
  }

  @override
  Future<List<ReviewNote>> getNotes(int restaurantId) async {
    return notes.where((note) => note.restaurantId == restaurantId).toList(growable: false);
  }

  @override
  Future<List<Restaurant>> getRestaurants() async => List.unmodifiable(restaurants);

  @override
  Future<void> removeBasketMatch(int matchId) async {
    basket.removeWhere((m) => m.id == matchId);
  }

  @override
  Future<void> upsertNote(int restaurantId, String text) async {
    final existingIndex = notes.indexWhere((n) => n.restaurantId == restaurantId);
    if (existingIndex == -1) {
      notes.add(ReviewNote(id: _nextNoteId++, restaurantId: restaurantId, text: text, updatedAt: DateTime.now()));
      return;
    }
    final existing = notes[existingIndex];
    notes[existingIndex] = ReviewNote(
      id: existing.id,
      restaurantId: existing.restaurantId,
      text: text,
      updatedAt: DateTime.now(),
    );
  }
}
