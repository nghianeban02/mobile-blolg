part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const [];
}

final class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

final class SettingsThemeModeChanged extends SettingsEvent {
  final ThemeMode mode;
  const SettingsThemeModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

final class SettingsFontScaleChanged extends SettingsEvent {
  final AppFontScale scale;
  const SettingsFontScaleChanged(this.scale);

  @override
  List<Object?> get props => [scale];
}
