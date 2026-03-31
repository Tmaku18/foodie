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
    final distance = units == 'km' ? restaurant.distanceMiles * 1.60934 : restaurant.distanceMiles;
    final suffix = units == 'km' ? 'km' : 'mi';
    final walkMins = ((restaurant.distanceMiles / 3.0) * 60).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            restaurant.buildingImageAsset,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: 'Restaurant building image',
          ),
          CarouselSlider(
            options: CarouselOptions(
              height: 120,
              autoPlay: true,
              viewportFraction: 1,
            ),
            items: restaurant.foodImageAssets
                .map(
                  (path) => Image.asset(
                    path,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: 'Food image',
                  ),
                )
                .toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant.name, style: Theme.of(context).textTheme.titleLarge),
                Text('${restaurant.category} · ⭐ ${restaurant.rating.toStringAsFixed(1)}'),
                Text('${distance.toStringAsFixed(1)} $suffix · ~$walkMins min walk'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
