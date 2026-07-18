import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/preferences/display_preferences.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Theme / font scale — persist qua [DisplayPreferences] (SharedPreferences).
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({DisplayPreferences? preferences})
    : _prefs = preferences ?? DisplayPreferences.instance,
      super(
        SettingsState(
          themeMode: (preferences ?? DisplayPreferences.instance).themeMode,
          fontScale: (preferences ?? DisplayPreferences.instance).fontScale,
        ),
      ) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsThemeModeChanged>(_onThemeChanged);
    on<SettingsFontScaleChanged>(_onFontScaleChanged);
  }

  final DisplayPreferences _prefs;

  Future<void> _onLoad(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.load();
    emit(
      state.copyWith(themeMode: _prefs.themeMode, fontScale: _prefs.fontScale),
    );
  }

  Future<void> _onThemeChanged(
    SettingsThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.setThemeMode(event.mode);
    emit(state.copyWith(themeMode: event.mode));
  }

  Future<void> _onFontScaleChanged(
    SettingsFontScaleChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.setFontScale(event.scale);
    emit(state.copyWith(fontScale: event.scale));
  }
}
