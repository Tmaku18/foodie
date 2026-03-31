import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/core/settings/preferences_service.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.isDarkMode = false,
    this.units = 'mi',
    this.walkingRadius = 2.0,
    this.notificationsEnabled = true,
    this.onboardingSeen = false,
  });

  final bool isDarkMode;
  final String units;
  final double walkingRadius;
  final bool notificationsEnabled;
  final bool onboardingSeen;

  SettingsState copyWith({
    bool? isDarkMode,
    String? units,
    double? walkingRadius,
    bool? notificationsEnabled,
    bool? onboardingSeen,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      units: units ?? this.units,
      walkingRadius: walkingRadius ?? this.walkingRadius,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  @override
  List<Object?> get props => [isDarkMode, units, walkingRadius, notificationsEnabled, onboardingSeen];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(const SettingsState());

  final PreferencesService _prefs;

  Future<void> load() async {
    emit(
      state.copyWith(
        isDarkMode: await _prefs.getDarkMode(),
        units: await _prefs.getUnits(),
        walkingRadius: await _prefs.getWalkingRadius(),
        notificationsEnabled: await _prefs.getNotificationsEnabled(),
        onboardingSeen: await _prefs.getOnboardingSeen(),
      ),
    );
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setDarkMode(value);
    emit(state.copyWith(isDarkMode: value));
  }

  Future<void> setUnits(String units) async {
    await _prefs.setUnits(units);
    emit(state.copyWith(units: units));
  }

  Future<void> setWalkingRadius(double radius) async {
    await _prefs.setWalkingRadius(radius);
    emit(state.copyWith(walkingRadius: radius));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> markOnboardingSeen() async {
    await _prefs.setOnboardingSeen(true);
    emit(state.copyWith(onboardingSeen: true));
  }
}
