import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'providers/auth_provider.dart';
import 'providers/ads_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/messages_provider.dart';
import 'models/ad_model.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/ads/create_ad_screen.dart';
import 'screens/ads/my_ads_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/ads/ad_detail_screen.dart';
import 'utils/theme.dart';
import 'services/error_reporting_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (WebViewPlatform.instance == null) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  // Initialize error reporting
  ErrorReportingService.initialize();

  // Capture all uncaught errors
  runZonedGuarded(
    () {
      runApp(const LocalVivaApp());
    },
    (error, stack) {
      ErrorReportingService.reportError(
        error: error,
        stackTrace: stack,
        context: 'Uncaught zone error',
      );
    },
  );
}

class LocalVivaApp extends StatelessWidget {
  const LocalVivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
      ],
      child: MaterialApp(
        title: 'Local Viva',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/create_ad': (context) => const CreateAdScreen(),
          '/my_ads': (context) => const MyAdsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/messages': (context) => const MessagesScreen(),
          '/ad-detail': (context) {
            final ad = ModalRoute.of(context)?.settings.arguments as AdModel?;
            if (ad == null) {
              return const Scaffold(body: Center(child: Text('Anúncio não encontrado')));
            }
            return AdDetailScreen(adId: ad.id);
          },
        },
      ),
    );
  }
}
