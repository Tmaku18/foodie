import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/features/settings/presentation/cubit/settings_cubit.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Foodie',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Offline-first Tinder for food:\n'
                '• Swipe right to save\n'
                '• Swipe left to skip this session\n'
                '• Everything is stored locally',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.read<SettingsCubit>().markOnboardingSeen(),
                child: const Text('Start Discovering'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
