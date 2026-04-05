import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:foodie/core/models.dart';

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.units,
  });

  final Restaurant restaurant;
  final String units;

  @override
  Widget build(BuildContext context) {
    final distance = units == 'km'
        ? restaurant.distanceMiles * 1.60934
        : restaurant.distanceMiles;
    final suffix = units == 'km' ? 'km' : 'mi';
    final walkMins = ((restaurant.distanceMiles / 3.0) * 60).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _safeAssetImage(
                    context,
                    path: restaurant.buildingImageAsset,
                    semanticLabel: 'Restaurant building image',
                    icon: Icons.storefront_outlined,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: double.infinity,
                      autoPlay: true,
                      viewportFraction: 1,
                    ),
                    items: restaurant.foodImageAssets
                        .map(
                          (path) => _safeAssetImage(
                            context,
                            path: path,
                            semanticLabel: 'Food image',
                            icon: Icons.restaurant_menu_outlined,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${restaurant.category} · ⭐ ${restaurant.rating.toStringAsFixed(1)}',
                ),
                Text(
                  '${distance.toStringAsFixed(1)} $suffix · ~$walkMins min walk',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _safeAssetImage(
    BuildContext context, {
    required String path,
    required String semanticLabel,
    required IconData icon,
    double? height,
  }) {
    return Image.asset(
      path,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) {
        final colors = Theme.of(context).colorScheme;
        return Container(
          height: height,
          width: double.infinity,
          color: colors.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(icon, size: 36, color: colors.onSurfaceVariant),
        );
      },
    );
  }
}
