import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared user preferences stored securely on device.
class AppPreferences {
  AppPreferences._();

  static const _storage = FlutterSecureStorage();
  static const _askSeenRatingKey = 'pref_ask_seen_rating';
  static const _notificationsEnabledKey = 'pref_notifications_enabled';
  static const _avatarPresetKey = 'pref_avatar_preset';
  static const _preferredLanguageKey = 'pref_preferred_language';
  static const _currentUsernameKey = 'current_username';
  static const _globalScope = 'global';

  static String _scopedKey(String base, String scope) => '${base}_$scope';

  static Future<String> _readCurrentScope() async {
    final username = await _storage.read(key: _currentUsernameKey);
    if (username == null || username.trim().isEmpty) {
      return _globalScope;
    }
    return username.trim().toLowerCase();
  }

  static Future<void> setCurrentUsername(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return;
    await _storage.write(key: _currentUsernameKey, value: clean);
  }

  static Future<bool> getAskSeenRating() async {
    final scope = await _readCurrentScope();
    final raw = await _storage.read(key: _scopedKey(_askSeenRatingKey, scope));
    if (raw == null && scope != _globalScope) {
      final globalRaw = await _storage.read(
        key: _scopedKey(_askSeenRatingKey, _globalScope),
      );
      if (globalRaw != null) {
        return globalRaw == 'true';
      }
    }
    if (raw == null) {
      return true;
    }
    return raw == 'true';
  }

  static Future<void> setAskSeenRating(bool value) async {
    final scope = await _readCurrentScope();
    await _storage.write(
      key: _scopedKey(_askSeenRatingKey, scope),
      value: value.toString(),
    );
  }

  static Future<bool> getNotificationsEnabled() async {
    final scope = await _readCurrentScope();
    final raw = await _storage.read(
      key: _scopedKey(_notificationsEnabledKey, scope),
    );
    if (raw == null) {
      return true;
    }
    return raw == 'true';
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final scope = await _readCurrentScope();
    await _storage.write(
      key: _scopedKey(_notificationsEnabledKey, scope),
      value: value.toString(),
    );
  }

  static Future<String> getAvatarPreset() async {
    final scope = await _readCurrentScope();
    final raw = await _storage.read(key: _scopedKey(_avatarPresetKey, scope));
    if (raw == null || raw.trim().isEmpty) {
      return 'coffee';
    }
    return raw.trim().toLowerCase();
  }

  static Future<void> setAvatarPreset(String value) async {
    final scope = await _readCurrentScope();
    final clean = value.trim().toLowerCase();
    if (clean.isEmpty) return;
    await _storage.write(
      key: _scopedKey(_avatarPresetKey, scope),
      value: clean,
    );
  }

  static Future<String> getPreferredLanguage() async {
    final scope = await _readCurrentScope();
    final raw = await _storage.read(
      key: _scopedKey(_preferredLanguageKey, scope),
    );
    if ((raw == null || raw.trim().isEmpty) && scope != _globalScope) {
      final globalRaw = await _storage.read(
        key: _scopedKey(_preferredLanguageKey, _globalScope),
      );
      if (globalRaw != null && globalRaw.trim().isNotEmpty) {
        return globalRaw.trim().toLowerCase();
      }
    }
    if (raw == null || raw.trim().isEmpty) {
      return 'fr';
    }
    return raw.trim().toLowerCase();
  }

  static Future<void> setPreferredLanguage(String value) async {
    final scope = await _readCurrentScope();
    final clean = value.trim().toLowerCase();
    if (clean.isEmpty) return;
    await _storage.write(
      key: _scopedKey(_preferredLanguageKey, scope),
      value: clean,
    );
    await _storage.write(
      key: _scopedKey(_preferredLanguageKey, _globalScope),
      value: clean,
    );
  }
}
