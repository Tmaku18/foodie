import 'package:flutter_test/flutter_test.dart';
import 'package:foodie/features/settings/presentation/cubit/settings_cubit.dart';
import '../support/fake_preferences_service.dart';

void main() {
  group('SettingsCubit', () {
    test('load picks persisted values', () async {
      final prefs = FakePreferencesService()
        ..darkMode = true
        ..units = 'km'
        ..radius = 3.5
        ..notificationsEnabled = false
        ..onboardingSeen = true;
      final cubit = SettingsCubit(prefs);

      await cubit.load();

      expect(cubit.state.isDarkMode, true);
      expect(cubit.state.units, 'km');
      expect(cubit.state.walkingRadius, 3.5);
      expect(cubit.state.notificationsEnabled, false);
      expect(cubit.state.onboardingSeen, true);
    });

    test('setDarkMode updates state', () async {
      final prefs = FakePreferencesService();
      final cubit = SettingsCubit(prefs);

      await cubit.setDarkMode(true);

      expect(cubit.state.isDarkMode, true);
    });

    test('markOnboardingSeen updates state', () async {
      final prefs = FakePreferencesService();
      final cubit = SettingsCubit(prefs);

      await cubit.markOnboardingSeen();

      expect(cubit.state.onboardingSeen, true);
    });
  });
}
