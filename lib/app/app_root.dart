import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/features/basket/presentation/pages/basket_page.dart';
import 'package:foodie/features/discover/presentation/pages/discover_page.dart';
import 'package:foodie/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:foodie/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:foodie/features/settings/presentation/pages/settings_page.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    if (!settings.onboardingSeen) {
      return const OnboardingPage();
    }

    final pages = const [DiscoverPage(), BasketPage(), SettingsPage()];
    final destinations = const [
      NavigationDestination(icon: Icon(Icons.local_fire_department), label: 'Discover'),
      NavigationDestination(icon: Icon(Icons.shopping_basket), label: 'Basket'),
      NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 700;
        if (!useRail) {
          return Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: destinations,
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (index) => setState(() => _index = index),
                destinations: destinations
                    .map((item) => NavigationRailDestination(icon: item.icon, label: Text(item.label)))
                    .toList(growable: false),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: IndexedStack(index: _index, children: pages)),
            ],
          ),
        );
      },
    );
  }
}
