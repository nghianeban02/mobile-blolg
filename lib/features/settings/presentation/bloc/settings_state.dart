part of 'settings_bloc.dart';

final class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final AppFontScale fontScale;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontScale = AppFontScale.medium,
  });

  SettingsState copyWith({ThemeMode? themeMode, AppFontScale? fontScale}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  @override
  List<Object?> get props => [themeMode, fontScale];
}
