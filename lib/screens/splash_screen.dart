import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../utils/storage_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (kDebugMode) {
      print('SplashScreen: Starting auth check');
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Debug: Check token before auth check
    final token = await StorageHelper.getToken();
    if (kDebugMode) {
      print('SplashScreen: Token before auth check: $token');
      print('SplashScreen: Token is null: ${token == null}');
      print('SplashScreen: Token is empty: ${token?.isEmpty ?? true}');
    }
    
    await authProvider.checkAuth();
    
    if (kDebugMode) {
      print('SplashScreen: After auth check - isAuthenticated: ${authProvider.isAuthenticated}');
      print('SplashScreen: User ID: ${authProvider.user?.id}');
      print('SplashScreen: User name: ${authProvider.user?.name}');
    }

    // Always navigate to home, authentication is optional
    if (kDebugMode) {
      print('SplashScreen: Navigating to home (auth: ${authProvider.isAuthenticated})');
    }
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.store,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Local Viva',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compre e venda no seu bairro',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
