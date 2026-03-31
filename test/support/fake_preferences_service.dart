import 'package:foodie/core/settings/preferences_service.dart';

class FakePreferencesService extends PreferencesService {
  bool darkMode = false;
  bool onboardingSeen = false;
  String units = 'mi';
  double radius = 2.0;
  bool notificationsEnabled = true;

  @override
  Future<bool> getDarkMode() async => darkMode;
  @override
  Future<bool> getOnboardingSeen() async => onboardingSeen;
  @override
  Future<String> getUnits() async => units;
  @override
  Future<double> getWalkingRadius() async => radius;
  @override
  Future<bool> getNotificationsEnabled() async => notificationsEnabled;
  @override
  Future<void> setDarkMode(bool value) async => darkMode = value;
  @override
  Future<void> setOnboardingSeen(bool value) async => onboardingSeen = value;
  @override
  Future<void> setUnits(String value) async => units = value;
  @override
  Future<void> setWalkingRadius(double value) async => radius = value;
  @override
  Future<void> setNotificationsEnabled(bool value) async => notificationsEnabled = value;
}
