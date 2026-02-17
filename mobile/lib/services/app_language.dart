import 'package:flutter/foundation.dart';

import 'app_preferences.dart';

class AppLanguage {
  AppLanguage._();

  static const Set<String> _supported = {'fr', 'en', 'es', 'de', 'it', 'pt'};

  static final ValueNotifier<String> _code = ValueNotifier<String>('fr');

  static ValueListenable<String> get listenable => _code;

  static String get currentCode => _code.value;

  static Future<void> initialize() async {
    await reloadFromPreferences();
  }

  static Future<void> reloadFromPreferences() async {
    try {
      final saved = await AppPreferences.getPreferredLanguage();
      setLanguage(saved);
    } catch (_) {
      setLanguage('fr');
    }
  }

  static void setLanguage(String rawCode) {
    final normalized = _normalize(rawCode);
    if (_code.value == normalized) return;
    _code.value = normalized;
  }

  static String _normalize(String rawCode) {
    final clean = rawCode.trim().toLowerCase();
    if (clean.isEmpty) return 'fr';
    final shortCode = clean.split(RegExp('[-_]')).first;
    if (_supported.contains(shortCode)) {
      return shortCode;
    }
    return 'fr';
  }
}
