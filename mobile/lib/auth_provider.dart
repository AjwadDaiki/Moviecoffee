import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'api_service.dart'; // Import pour utiliser l'URL automatique
import 'services/app_language.dart';
import 'services/app_preferences.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      await AppLanguage.reloadFromPreferences();
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final cleanEmail = email.trim().toLowerCase();
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': cleanEmail, 'password': password.trim()},
      );
      await _storage.write(
        key: 'jwt_token',
        value: response.data['access_token'],
      );
      await _syncCurrentUsername(response.data);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      print("❌ LOGIN ERROR: ${e.response?.data}");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final cleanEmail = email.trim().toLowerCase();
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'username': username.trim(),
          'email': cleanEmail,
          'password': password.trim(),
        },
      );
      await _storage.write(
        key: 'jwt_token',
        value: response.data['access_token'],
      );
      await _syncCurrentUsername(response.data, fallback: username.trim());
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      print("❌ SIGNUP ERROR: ${e.response?.data}");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'current_username');
    await AppLanguage.reloadFromPreferences();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> _syncCurrentUsername(
    Map<String, dynamic> payload, {
    String? fallback,
  }) async {
    final directUsername =
        payload['username']?.toString() ??
        payload['user']?['username']?.toString();
    if (directUsername != null && directUsername.trim().isNotEmpty) {
      await AppPreferences.setCurrentUsername(directUsername.trim());
      await AppLanguage.reloadFromPreferences();
      return;
    }

    if (fallback != null && fallback.trim().isNotEmpty) {
      await AppPreferences.setCurrentUsername(fallback.trim());
      await AppLanguage.reloadFromPreferences();
      return;
    }

    try {
      final token = await _storage.read(key: 'jwt_token');
      final profileResponse = await _dio.get(
        '/me/profile',
        options: Options(
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
      final apiUsername =
          profileResponse.data?['user']?['username']?.toString() ??
          profileResponse.data?['username']?.toString();
      if (apiUsername != null && apiUsername.trim().isNotEmpty) {
        await AppPreferences.setCurrentUsername(apiUsername.trim());
        await AppLanguage.reloadFromPreferences();
      }
    } catch (_) {}
  }
}
