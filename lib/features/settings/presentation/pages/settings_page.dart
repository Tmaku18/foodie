import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/core/di/injection.dart';
import 'package:foodie/core/services/background_picks_service.dart';
import 'package:foodie/core/services/local_notification_service.dart';
import 'package:foodie/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:foodie/features/settings/presentation/cubit/settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<List<int>> _picksFuture;
  bool _importingFromGoogle = false;

  @override
  void initState() {
    super.initState();
    _picksFuture = getIt<BackgroundPicksService>().getTodaysPicks();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsCubit>().state;
    final picksService = getIt<BackgroundPicksService>();
    final notifications = getIt<LocalNotificationService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Dark mode'),
            value: state.isDarkMode,
            onChanged: (value) => context.read<SettingsCubit>().setDarkMode(value),
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: state.notificationsEnabled,
            onChanged: (value) => context.read<SettingsCubit>().setNotificationsEnabled(value),
          ),
          const SizedBox(height: 8),
          Text('Walking radius: ${state.walkingRadius.toStringAsFixed(1)} miles'),
          Slider(
            min: 0.5,
            max: 5.0,
            divisions: 9,
            value: state.walkingRadius,
            label: state.walkingRadius.toStringAsFixed(1),
            onChanged: (value) => context.read<SettingsCubit>().setWalkingRadius(value),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'mi', label: Text('Miles')),
              ButtonSegment(value: 'km', label: Text('Kilometers')),
            ],
            selected: {state.units},
            onSelectionChanged: (set) => context.read<SettingsCubit>().setUnits(set.first),
          ),
          const Divider(),
          FilledButton.icon(
            onPressed: _importingFromGoogle
                ? null
                : () async {
                    setState(() => _importingFromGoogle = true);
                    try {
                      final count = await context.read<DiscoverCubit>().refreshFromGoogleImport();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Imported $count restaurants from Google Places')),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google import failed. Check API key and connectivity.')),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _importingFromGoogle = false);
                      }
                    }
                  },
            icon: const Icon(Icons.cloud_download_outlined),
            label: Text(_importingFromGoogle ? 'Importing...' : 'Refresh from Google Places'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final restaurants = context.read<DiscoverCubit>().state.restaurants.map((e) => e.id).toList();
              await picksService.prepareTodaysPicks(restaurants);
              setState(() {
                _picksFuture = picksService.getTodaysPicks();
              });
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Today\'s Picks refreshed')));
            },
            icon: const Icon(Icons.sync),
            label: const Text('Run background picks job'),
          ),
          FilledButton.tonalIcon(
            onPressed: state.notificationsEnabled
                ? () async {
                    await notifications.showTopPickReminder();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder sent')));
                  }
                : null,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send local reminder now'),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<int>>(
            future: _picksFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Today\'s Picks: loading...');
              }
              return Text('Today\'s Picks: ${snapshot.data!.join(', ')}');
            },
          ),
        ],
      ),
    );
  }
}
