class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.distanceMiles,
    required this.rating,
    required this.buildingImageAsset,
    required this.foodImageAssets,
  });

  final int id;
  final String name;
  final String category;
  final double distanceMiles;
  final double rating;
  final String buildingImageAsset;
  final List<String> foodImageAssets;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.description,
  });

  final int id;
  final int restaurantId;
  final String name;
  final double price;
  final String description;
}

class BasketMatch {
  const BasketMatch({
    required this.id,
    required this.restaurantId,
    required this.createdAt,
  });

  final int id;
  final int restaurantId;
  final DateTime createdAt;
}

class ReviewNote {
  const ReviewNote({
    required this.id,
    required this.restaurantId,
    required this.text,
    required this.updatedAt,
  });

  final int id;
  final int restaurantId;
  final String text;
  final DateTime updatedAt;
}
