import 'package:foodie/core/db/app_database.dart';
import 'package:foodie/core/models.dart';
import 'package:foodie/data/seed/seed_data.dart';
import 'package:foodie/domain/repositories/food_repository.dart';

class LocalFoodRepository implements FoodRepository {
  LocalFoodRepository(this._database);

  final AppDatabase _database;

  Future<void> ensureSeeded() async {
    final db = await _database.database;
    final existing = await db.query('restaurants', limit: 1);
    if (existing.isNotEmpty) return;

    final batch = db.batch();
    for (final restaurant in demoRestaurants) {
      batch.insert('restaurants', {
        'id': restaurant.id,
        'name': restaurant.name,
        'category': restaurant.category,
        'distance_miles': restaurant.distanceMiles,
        'rating': restaurant.rating,
        'building_image_asset': restaurant.buildingImageAsset,
        'food_images_csv': restaurant.foodImageAssets.join(','),
      });
    }
    for (final item in demoMenuItems) {
      batch.insert('menu_items', {
        'id': item.id,
        'restaurant_id': item.restaurantId,
        'name': item.name,
        'price': item.price,
        'description': item.description,
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> addBasketMatch(int restaurantId) async {
    final db = await _database.database;
    await db.insert('basket_matches', {
      'restaurant_id': restaurantId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> clearBasket() async {
    final db = await _database.database;
    await db.delete('basket_matches');
  }

  @override
  Future<void> deleteNote(int noteId) async {
    final db = await _database.database;
    await db.delete('reviews_or_notes', where: 'id = ?', whereArgs: [noteId]);
  }

  @override
  Future<List<BasketMatch>> getBasketMatches() async {
    final db = await _database.database;
    final rows = await db.query('basket_matches', orderBy: 'created_at DESC');
    return rows
        .map((row) => BasketMatch(
              id: row['id'] as int,
              restaurantId: row['restaurant_id'] as int,
              createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
            ))
        .toList();
  }

  @override
  Future<List<MenuItem>> getMenuByRestaurant(int restaurantId) async {
    final db = await _database.database;
    final rows = await db.query(
      'menu_items',
      where: 'restaurant_id = ?',
      whereArgs: [restaurantId],
    );
    return rows
        .map((row) => MenuItem(
              id: row['id'] as int,
              restaurantId: row['restaurant_id'] as int,
              name: row['name'] as String,
              price: (row['price'] as num).toDouble(),
              description: row['description'] as String,
            ))
        .toList();
  }

  @override
  Future<List<ReviewNote>> getNotes(int restaurantId) async {
    final db = await _database.database;
    final rows = await db.query(
      'reviews_or_notes',
      where: 'restaurant_id = ?',
      whereArgs: [restaurantId],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map((row) => ReviewNote(
              id: row['id'] as int,
              restaurantId: row['restaurant_id'] as int,
              text: row['text'] as String,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
            ))
        .toList();
  }

  @override
  Future<List<Restaurant>> getRestaurants() async {
    final db = await _database.database;
    final rows = await db.query('restaurants');
    return rows
        .map((row) => Restaurant(
              id: row['id'] as int,
              name: row['name'] as String,
              category: row['category'] as String,
              distanceMiles: (row['distance_miles'] as num).toDouble(),
              rating: (row['rating'] as num).toDouble(),
              buildingImageAsset: row['building_image_asset'] as String,
              foodImageAssets: (row['food_images_csv'] as String).split(','),
            ))
        .toList();
  }

  @override
  Future<void> removeBasketMatch(int matchId) async {
    final db = await _database.database;
    await db.delete('basket_matches', where: 'id = ?', whereArgs: [matchId]);
  }

  @override
  Future<void> upsertNote(int restaurantId, String text) async {
    final db = await _database.database;
    final existing = await db.query(
      'reviews_or_notes',
      where: 'restaurant_id = ?',
      whereArgs: [restaurantId],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('reviews_or_notes', {
        'restaurant_id': restaurantId,
        'text': text,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      return;
    }
    await db.update(
      'reviews_or_notes',
      {
        'text': text,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [existing.first['id']],
    );
  }
}
