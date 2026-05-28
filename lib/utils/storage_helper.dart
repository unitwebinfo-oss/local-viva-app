import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static Future<void> saveToken(String token) async {
    if (kDebugMode) {
      print('StorageHelper: Attempting to save token: $token');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (kDebugMode) {
      print('StorageHelper: Token saved to SharedPreferences');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (kDebugMode) {
      print('StorageHelper: Token retrieved from SharedPreferences: $token');
      print('StorageHelper: Token is null: ${token == null}');
      print('StorageHelper: Token is empty: ${token?.isEmpty ?? true}');
    }
    
    return token;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toString());
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (kDebugMode) {
      print('StorageHelper: Cleared SharedPreferences');
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final result = token != null && token.isNotEmpty;
    if (kDebugMode) {
      print('StorageHelper: isLoggedIn = $result (token: $token)');
    }
    return result;
  }
}
