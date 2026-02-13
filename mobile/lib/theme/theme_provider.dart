import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// =============================================================================
/// THEME PROVIDER - Gestion du thème clair/sombre
/// =============================================================================

enum ThemeOption { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'theme_mode';

  ThemeOption _themeOption = ThemeOption.system;
  bool _isDarkMode = false;

  ThemeOption get themeOption => _themeOption;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final storedTheme = await _storage.read(key: _storageKey);

    if (storedTheme != null) {
      switch (storedTheme) {
        case 'light':
          _themeOption = ThemeOption.light;
          _isDarkMode = false;
          break;
        case 'dark':
          _themeOption = ThemeOption.dark;
          _isDarkMode = true;
          break;
        default:
          _themeOption = ThemeOption.system;
          _updateFromSystem();
      }
    } else {
      _updateFromSystem();
    }

    notifyListeners();
  }

  void _updateFromSystem() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;
  }

  Future<void> setTheme(ThemeOption option) async {
    _themeOption = option;

    switch (option) {
      case ThemeOption.light:
        _isDarkMode = false;
        await _storage.write(key: _storageKey, value: 'light');
        break;
      case ThemeOption.dark:
        _isDarkMode = true;
        await _storage.write(key: _storageKey, value: 'dark');
        break;
      case ThemeOption.system:
        _updateFromSystem();
        await _storage.write(key: _storageKey, value: 'system');
        break;
    }

    notifyListeners();
  }

  /// Toggle entre light et dark (ignore system)
  Future<void> toggleTheme() async {
    if (_isDarkMode) {
      await setTheme(ThemeOption.light);
    } else {
      await setTheme(ThemeOption.dark);
    }
  }

  /// Update when system theme changes
  void onSystemThemeChanged() {
    if (_themeOption == ThemeOption.system) {
      _updateFromSystem();
      notifyListeners();
    }
  }

  /// Label du thème actuel
  String get themeLabel {
    switch (_themeOption) {
      case ThemeOption.light:
        return 'Clair';
      case ThemeOption.dark:
        return 'Sombre';
      case ThemeOption.system:
        return 'Système';
    }
  }

  /// Icône du thème actuel
  IconData get themeIcon {
    switch (_themeOption) {
      case ThemeOption.light:
        return Icons.light_mode_rounded;
      case ThemeOption.dark:
        return Icons.dark_mode_rounded;
      case ThemeOption.system:
        return Icons.brightness_auto_rounded;
    }
  }
}
