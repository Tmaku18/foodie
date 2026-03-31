import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/features/basket/presentation/cubit/basket_cubit.dart';
import 'package:foodie/features/details/presentation/pages/details_page.dart';
import 'package:foodie/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:foodie/features/discover/presentation/widgets/restaurant_card.dart';
import 'package:foodie/features/settings/presentation/cubit/settings_cubit.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(child: Text(state.error!));
        }

        final visible = state.visible.where((r) => r.distanceMiles <= settings.walkingRadius).toList(growable: false);
        if (visible.isEmpty) {
          return const Center(
            child: Text(
              'No restaurants available in the current walking radius.\nAdjust radius in Settings.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final current = visible.first;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DetailsPage(restaurant: current)),
                  ),
                  child: Dismissible(
                    key: ValueKey(current.id),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        context.read<DiscoverCubit>().swipeLeft(current, radiusMiles: settings.walkingRadius);
                      } else {
                        context.read<DiscoverCubit>().swipeRight(current);
                        context.read<BasketCubit>().load();
                      }
                    },
                    background: _swipeBg('Save', Colors.green, Alignment.centerLeft),
                    secondaryBackground: _swipeBg('Skip', Colors.red, Alignment.centerRight),
                    child: RestaurantCard(restaurant: current, units: settings.units),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Swipe right to match • Swipe left to skip', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }

  Widget _swipeBg(String label, Color color, Alignment alignment) {
    return Container(
      color: color.withValues(alpha: 0.2),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(label),
    );
  }
}
