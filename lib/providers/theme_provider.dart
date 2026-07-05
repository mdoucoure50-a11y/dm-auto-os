import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
      return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
    });

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final value = prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_themeModeKey, mode.name);
  }

  void toggleDarkMode() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }
}
