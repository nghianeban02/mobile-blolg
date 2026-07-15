import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontScale { small, medium, large }

class DisplayPreferences extends ChangeNotifier {
  DisplayPreferences._();

  static final DisplayPreferences instance = DisplayPreferences._();

  static const _themeKey = 'display_theme';
  static const _fontKey = 'display_font_size';

  ThemeMode _themeMode = ThemeMode.system;
  AppFontScale _fontScale = AppFontScale.medium;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  AppFontScale get fontScale => _fontScale;
  double get textScale => switch (_fontScale) {
    AppFontScale.small => 0.9,
    AppFontScale.medium => 1.0,
    AppFontScale.large => 1.15,
  };

  Future<void> load() async {
    if (_loaded) return;
    final preferences = await SharedPreferences.getInstance();
    _themeMode = _themeFromName(preferences.getString(_themeKey));
    _fontScale = _fontFromName(preferences.getString(_fontKey));
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, value.name);
  }

  Future<void> setFontScale(AppFontScale value) async {
    if (_fontScale == value) return;
    _fontScale = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_fontKey, value.name);
  }

  ThemeMode _themeFromName(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  AppFontScale _fontFromName(String? value) => switch (value) {
    'small' => AppFontScale.small,
    'large' => AppFontScale.large,
    _ => AppFontScale.medium,
  };
}
