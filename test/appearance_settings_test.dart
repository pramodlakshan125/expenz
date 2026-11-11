import 'package:expenz/services/appearance_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to the device theme and handles an unknown saved value', () async {
    SharedPreferences.setMockInitialValues({});
    await AppearanceSettings.load();
    expect(AppearanceSettings.mode.value, ThemeMode.system);
    SharedPreferences.setMockInitialValues({'appearance': 'unknown'});
    await AppearanceSettings.load();
    expect(AppearanceSettings.mode.value, ThemeMode.system);
  });

  test('saves and restores each appearance choice', () async {
    SharedPreferences.setMockInitialValues({});
    await AppearanceSettings.load();
    for (final mode in ThemeMode.values) {
      await AppearanceSettings.setMode(mode);
      expect(AppearanceSettings.mode.value, mode);
      AppearanceSettings.mode.value = ThemeMode.system;
      await AppearanceSettings.load();
      expect(AppearanceSettings.mode.value, mode);
    }
  });
}
