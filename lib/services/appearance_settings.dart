import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceSettings {
  static final mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('appearance');
    mode.value = ThemeMode.values.firstWhere(
      (value) => value.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  static Future<void> setMode(ThemeMode value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString('appearance', value.name);
    if (!saved) throw StateError('Could not persist appearance');
    mode.value = value;
  }

  static String label(ThemeMode value) => switch (value) {
    ThemeMode.system => 'System default',
    ThemeMode.dark => 'Dark',
    ThemeMode.light => 'Light',
  };
}
