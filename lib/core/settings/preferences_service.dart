import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _darkModeKey = 'dark_mode';
  static const _onboardingKey = 'onboarding_seen';
  static const _unitsKey = 'distance_units';
  static const _radiusKey = 'walking_radius';
  static const _notificationsKey = 'notifications_enabled';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> getDarkMode() async => (await _prefs).getBool(_darkModeKey) ?? false;
  Future<void> setDarkMode(bool value) async => (await _prefs).setBool(_darkModeKey, value);

  Future<bool> getOnboardingSeen() async => (await _prefs).getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingSeen(bool value) async => (await _prefs).setBool(_onboardingKey, value);

  Future<String> getUnits() async => (await _prefs).getString(_unitsKey) ?? 'mi';
  Future<void> setUnits(String units) async => (await _prefs).setString(_unitsKey, units);

  Future<double> getWalkingRadius() async => (await _prefs).getDouble(_radiusKey) ?? 2.0;
  Future<void> setWalkingRadius(double value) async => (await _prefs).setDouble(_radiusKey, value);

  Future<bool> getNotificationsEnabled() async => (await _prefs).getBool(_notificationsKey) ?? true;
  Future<void> setNotificationsEnabled(bool value) async => (await _prefs).setBool(_notificationsKey, value);
}
