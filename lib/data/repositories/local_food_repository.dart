import 'package:foodie/core/db/app_database.dart';
import 'package:foodie/core/models.dart';
import 'package:foodie/data/import/google_places_import_service.dart';
import 'package:foodie/data/seed/generated_google_places_seed.dart';
import 'package:foodie/data/seed/generated_menu_items_seed.dart';
import 'package:foodie/data/seed/seed_data.dart';
import 'package:foodie/domain/repositories/food_repository.dart';

class LocalFoodRepository implements FoodRepository {
  LocalFoodRepository(this._database, this._googlePlacesImportService);

  static const _targetItemsPerRestaurant = 6;
  static const _placeholderDescription =
      'Placeholder price estimate (*) - replace with verified menu pricing when available.';

  final AppDatabase _database;
  final GooglePlacesImportService _googlePlacesImportService;
  Future<void>? _seedFuture;

  Future<void> _ensureSeededReady() {
    return _seedFuture ??= ensureSeeded();
  }

  Future<void> ensureSeeded() async {
    final db = await _database.database;
    final existing = await db.query('restaurants', limit: 1);
    if (existing.isNotEmpty) return;

    final seedRestaurants = generatedGooglePlacesRestaurants.isNotEmpty
        ? generatedGooglePlacesRestaurants
        : demoRestaurants;
    final seedMenus = generatedGooglePlacesRestaurants.isNotEmpty
        ? _resolveGeneratedSeedMenus(generatedGooglePlacesRestaurants)
        : demoMenuItems;
    final source = generatedGooglePlacesRestaurants.isNotEmpty
        ? 'google_places_seed'
        : 'seed_local';

    final batch = db.batch();
    for (final restaurant in seedRestaurants) {
      batch.insert('restaurants', {
        'id': restaurant.id,
        'name': restaurant.name,
        'category': restaurant.category,
        'distance_miles': restaurant.distanceMiles,
        'rating': restaurant.rating,
        'building_image_asset': restaurant.buildingImageAsset,
        'food_images_csv': restaurant.foodImageAssets.join(','),
        'source': source,
      });
    }
    for (final item in seedMenus) {
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

  List<MenuItem> _buildPlaceholderMenuItems(
    List<Restaurant> restaurants, {
    required int startId,
    required int itemsPerRestaurant,
  }) {
    final menuItems = <MenuItem>[];
    var menuId = startId;
    for (final restaurant in restaurants) {
      final templates = _templatesForCategory(restaurant.category);
      for (var i = 0; i < itemsPerRestaurant; i++) {
        final template = templates[i % templates.length];
        menuItems.add(
          MenuItem(
            id: menuId,
            restaurantId: restaurant.id,
            name: template.name,
            price: template.price,
            description: _placeholderDescription,
          ),
        );
        menuId += 1;
      }
    }
    return menuItems;
  }

  List<MenuItem> _resolveGeneratedSeedMenus(List<Restaurant> restaurants) {
    if (generatedMenuItems.isEmpty) {
      return _buildPlaceholderMenuItems(
        restaurants,
        startId: 1,
        itemsPerRestaurant: _targetItemsPerRestaurant,
      );
    }

    final restaurantIds = restaurants.map((r) => r.id).toSet();
    final selected = generatedMenuItems
        .where((item) => restaurantIds.contains(item.restaurantId))
        .toList(growable: true);

    var nextMenuId = selected.fold<int>(
          1,
          (maxId, item) => item.id > maxId ? item.id : maxId,
        ) +
        1;

    for (final restaurant in restaurants) {
      final existingCount = selected
          .where((item) => item.restaurantId == restaurant.id)
          .length;
      if (existingCount >= _targetItemsPerRestaurant) {
        continue;
      }
      final needed = _targetItemsPerRestaurant - existingCount;
      selected.addAll(
        _buildPlaceholderMenuItems(
          [restaurant],
          startId: nextMenuId,
          itemsPerRestaurant: needed,
        ),
      );
      nextMenuId += needed;
    }
    return selected;
  }

  List<_PlaceholderTemplate> _templatesForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('breakfast')) {
      return const [
        _PlaceholderTemplate('Breakfast Sandwich', 8.99),
        _PlaceholderTemplate('Chicken & Waffles', 13.49),
        _PlaceholderTemplate('Veggie Omelet', 11.99),
        _PlaceholderTemplate('Pancake Stack', 9.49),
        _PlaceholderTemplate('Hash Browns', 4.49),
        _PlaceholderTemplate('Coffee', 2.99),
      ];
    }
    if (c.contains('mexican')) {
      return const [
        _PlaceholderTemplate('Street Tacos (3)', 12.99),
        _PlaceholderTemplate('Chicken Burrito Bowl', 11.99),
        _PlaceholderTemplate('Cheese Quesadilla', 10.49),
        _PlaceholderTemplate('Chips & Salsa', 5.99),
        _PlaceholderTemplate('Guacamole & Chips', 8.99),
        _PlaceholderTemplate('Horchata', 3.49),
      ];
    }
    if (c.contains('fast food')) {
      return const [
        _PlaceholderTemplate('Cheeseburger Combo', 9.99),
        _PlaceholderTemplate('Chicken Sandwich', 8.99),
        _PlaceholderTemplate('6pc Wings', 7.99),
        _PlaceholderTemplate('Large Fries', 3.99),
        _PlaceholderTemplate('Milkshake', 4.49),
        _PlaceholderTemplate('Soft Drink', 2.49),
      ];
    }
    if (c.contains('bar') || c.contains('brewery') || c.contains('beer')) {
      return const [
        _PlaceholderTemplate('House Wings', 11.99),
        _PlaceholderTemplate('Loaded Nachos', 10.99),
        _PlaceholderTemplate('Burger & Fries', 13.99),
        _PlaceholderTemplate('Fish Tacos (2)', 12.99),
        _PlaceholderTemplate('Draft Pint', 6.99),
        _PlaceholderTemplate('House Salad', 8.49),
      ];
    }
    if (c.contains('fine dining') || c.contains('spanish') || c.contains('persian')) {
      return const [
        _PlaceholderTemplate('Chef Special Entree', 24.99),
        _PlaceholderTemplate('Roasted Chicken Plate', 19.99),
        _PlaceholderTemplate('Seasonal Pasta', 18.49),
        _PlaceholderTemplate('Grilled Salmon', 23.49),
        _PlaceholderTemplate('Soup of the Day', 8.99),
        _PlaceholderTemplate('Dessert', 9.49),
      ];
    }
    return const [
      _PlaceholderTemplate('House Burger', 12.99),
      _PlaceholderTemplate('Chicken Tenders Basket', 11.49),
      _PlaceholderTemplate('Caesar Salad', 9.49),
      _PlaceholderTemplate('Grilled Chicken Sandwich', 10.99),
      _PlaceholderTemplate('Fries', 3.99),
      _PlaceholderTemplate('Soft Drink', 2.79),
    ];
  }

  @override
  Future<void> addBasketMatch(int restaurantId) async {
    await _ensureSeededReady();
    final db = await _database.database;
    await db.insert('basket_matches', {
      'restaurant_id': restaurantId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> clearBasket() async {
    await _ensureSeededReady();
    final db = await _database.database;
    await db.delete('basket_matches');
  }

  @override
  Future<void> deleteNote(int noteId) async {
    await _ensureSeededReady();
    final db = await _database.database;
    await db.delete('reviews_or_notes', where: 'id = ?', whereArgs: [noteId]);
  }

  @override
  Future<List<BasketMatch>> getBasketMatches() async {
    await _ensureSeededReady();
    final db = await _database.database;
    final rows = await db.query('basket_matches', orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => BasketMatch(
            id: row['id'] as int,
            restaurantId: row['restaurant_id'] as int,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] as int,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<List<MenuItem>> getMenuByRestaurant(int restaurantId) async {
    await _ensureSeededReady();
    final db = await _database.database;
    final rows = await db.query(
      'menu_items',
      where: 'restaurant_id = ?',
      whereArgs: [restaurantId],
    );
    return rows
        .map(
          (row) => MenuItem(
            id: row['id'] as int,
            restaurantId: row['restaurant_id'] as int,
            name: row['name'] as String,
            price: (row['price'] as num).toDouble(),
            description: row['description'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<List<ReviewNote>> getNotes(int restaurantId) async {
    await _ensureSeededReady();
    final db = await _database.database;
    final rows = await db.query(
      'reviews_or_notes',
      where: 'restaurant_id = ?',
      whereArgs: [restaurantId],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (row) => ReviewNote(
            id: row['id'] as int,
            restaurantId: row['restaurant_id'] as int,
            text: row['text'] as String,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              row['updated_at'] as int,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<List<Restaurant>> getRestaurants() async {
    await _ensureSeededReady();
    final db = await _database.database;
    final rows = await db.query('restaurants');
    return rows
        .map(
          (row) => Restaurant(
            id: row['id'] as int,
            name: row['name'] as String,
            category: row['category'] as String,
            distanceMiles: (row['distance_miles'] as num).toDouble(),
            rating: (row['rating'] as num).toDouble(),
            buildingImageAsset: row['building_image_asset'] as String,
            foodImageAssets: (row['food_images_csv'] as String).split(','),
          ),
        )
        .toList();
  }

  @override
  Future<int> refreshRestaurantsFromGoogle() async {
    final imported = await _googlePlacesImportService.fetchNearbyRestaurants();
    final db = await _database.database;
    final batch = db.batch();
    for (final record in imported) {
      final existing = await db.query(
        'restaurants',
        columns: ['id', 'building_image_asset', 'food_images_csv'],
        where: 'external_place_id = ?',
        whereArgs: [record.externalPlaceId],
        limit: 1,
      );
      final id = existing.isNotEmpty
          ? existing.first['id'] as int
          : _stableIntId(record.externalPlaceId);
      final existingBuildingImageAsset = existing.isNotEmpty
          ? (existing.first['building_image_asset'] as String?)
          : null;
      final existingFoodImagesCsv = existing.isNotEmpty
          ? (existing.first['food_images_csv'] as String?)
          : null;
      final payload = {
        'id': id,
        'name': record.name,
        'category': record.category,
        'distance_miles': record.distanceMiles,
        'rating': record.rating,
        'building_image_asset':
            existingBuildingImageAsset ??
            'assets/images/restaurant_building.png',
        'food_images_csv':
            existingFoodImagesCsv ??
            'assets/images/food_1.png,assets/images/food_2.png,assets/images/food_3.png',
        'external_place_id': record.externalPlaceId,
        'source': record.source,
        'latitude': record.latitude,
        'longitude': record.longitude,
        'address_text': record.addressText,
      };

      if (existing.isNotEmpty) {
        batch.update('restaurants', payload, where: 'id = ?', whereArgs: [id]);
      } else {
        batch.insert('restaurants', payload);
      }
    }
    await batch.commit(noResult: true);
    return imported.length;
  }

  @override
  Future<void> removeBasketMatch(int matchId) async {
    await _ensureSeededReady();
    final db = await _database.database;
    await db.delete('basket_matches', where: 'id = ?', whereArgs: [matchId]);
  }

  @override
  Future<void> upsertNote(int restaurantId, String text) async {
    await _ensureSeededReady();
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
      {'text': text, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [existing.first['id']],
    );
  }

  int _stableIntId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}

class _PlaceholderTemplate {
  const _PlaceholderTemplate(this.name, this.price);

  final String name;
  final double price;
}
