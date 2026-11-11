import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceSettings {
  static final mode = ValueNotifier(ThemeMode.system);
  static late SharedPreferences _preferences;

  static Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    final saved = _preferences.getString('appearance');
    mode.value = ThemeMode.values.firstWhere(
      (value) => value.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  static Future<void> setMode(ThemeMode value) async {
    await _preferences.setString('appearance', value.name);
    mode.value = value;
  }

  static String label(ThemeMode value) => switch (value) {
    ThemeMode.system => 'System default',
    ThemeMode.dark => 'Dark',
    ThemeMode.light => 'Light',
  };
}
