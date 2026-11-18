import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class StorageService {
  static const String _tokenKey = 'fintrack_auth_token';
  static const String _userKey = 'fintrack_current_user';
  static const String _baseUrlKey = 'fintrack_base_url';
  static const String _currencyKey = 'fintrack_currency';
  static const String _themeModeKey = 'fintrack_dark_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  // User Profile Management
  Future<void> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _prefs.setString(_userKey, jsonStr);
  }

  UserModel? getUser() {
    final jsonStr = _prefs.getString(_userKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  // Custom Base URL
  Future<void> saveBaseUrl(String url) async {
    await _prefs.setString(_baseUrlKey, url);
  }

  String? getBaseUrl() {
    return _prefs.getString(_baseUrlKey);
  }

  // Currency
  Future<void> saveCurrency(String symbol) async {
    await _prefs.setString(_currencyKey, symbol);
  }

  String getCurrency() {
    return _prefs.getString(_currencyKey) ?? '\$';
  }

  // Theme
  Future<void> saveDarkMode(bool isDark) async {
    await _prefs.setBool(_themeModeKey, isDark);
  }

  bool isDarkMode() {
    return _prefs.getBool(_themeModeKey) ?? true; // default dark
  }

  // Clear all session
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
  }
}
