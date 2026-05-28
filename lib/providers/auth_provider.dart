import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/storage_helper.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> logout() async {
    try {
      if (kDebugMode) {
        print('AuthProvider: Starting logout process');
      }
      
      // Debug: Check token before clearing
      final token = await StorageHelper.getToken();
      if (kDebugMode) {
        print('AuthProvider: Token before logout: $token');
      }
      
      await ApiService.post(ApiConfig.logout, {});
    } catch (e) {
      if (kDebugMode) {
        print('AuthProvider: Logout API error: $e');
      }
      // Ignore logout API errors
    }
    
    await StorageHelper.clearAll();
    
    // Debug: Verify token after clearing
    final tokenAfter = await StorageHelper.getToken();
    if (kDebugMode) {
      print('AuthProvider: Token after clearing: $tokenAfter');
    }
    
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    // Prevent multiple simultaneous login attempts
    if (_isLoading) {
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Attempting login for: $email');
      }
      
      final response = await ApiService.post(
        ApiConfig.login,
        {'email': email, 'password': password},
      );

      if (kDebugMode) {
        print('Login response: $response');
      }

      if (response['success'] == true) {
        if (kDebugMode) {
          print('Login successful, token: ${response['token']}');
          print('User data: ${response['user']}');
        }
        await StorageHelper.saveToken(response['token']);
        
        // Debug: Verify token was saved
        final savedToken = await StorageHelper.getToken();
        if (kDebugMode) {
          print('Token verification after save: $savedToken');
        }
        
        _user = UserModel.fromJson(response['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _error = 'Erro ao fazer login';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        ApiConfig.register,
        {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );

      if (response['success'] == true) {
        await StorageHelper.saveToken(response['token']);
        _user = UserModel.fromJson(response['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _error = 'Erro ao criar conta';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkAuth() async {
    final isLoggedIn = await StorageHelper.isLoggedIn();
    
    if (kDebugMode) {
      print('checkAuth: isLoggedIn = $isLoggedIn');
    }
    
    if (!isLoggedIn) {
      if (kDebugMode) {
        print('checkAuth: User not logged in, returning false');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        print('Fetching user data from: ${ApiConfig.me}');
      }
      final response = await ApiService.get(ApiConfig.me);
      
      if (kDebugMode) {
        print('User data response: $response');
      }
      
      if (response['success'] == true) {
        _user = UserModel.fromJson(response['user']);
        if (kDebugMode) {
          print('User authenticated: ${_user?.name} (ID: ${_user?.id})');
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auth check failed: $e');
      }
      // If token is invalid, clear storage
      await StorageHelper.clearAll();
      if (kDebugMode) {
        print('Auth check: Cleared storage due to invalid token');
      }
      _user = null;
      notifyListeners();
    }
    return false;
  }
}
