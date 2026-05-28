import 'dart:math';
import '../services/api_service.dart';
import '../config/api_config.dart';

class BannerService {
  static Future<List<Map<String, dynamic>>> getBanners({
    String position = 'top',
    String pageScope = 'both',
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'position': position,
        'page_scope': pageScope,
        'limit': limit.toString(),
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final endpoint = '/banners?$queryString';
      final fullUrl = '${ApiConfig.baseUrl}$endpoint';
      print('DEBUG: Fetching banners from: $fullUrl');
      
      final response = await ApiService.get(endpoint);

      print('DEBUG: Banner response: $response');

      if (response['success'] == true) {
        final banners = List<Map<String, dynamic>>.from(response['banners'] ?? []);
        print('DEBUG: Banners found: ${banners.length}');
        return banners;
      }
      print('DEBUG: API response not successful');
      return [];
    } catch (e) {
      print('DEBUG: Error fetching banners: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getRandomBanner({
    String position = 'top',
    String pageScope = 'both',
  }) async {
    try {
      final banners = await getBanners(
        position: position,
        pageScope: pageScope,
        limit: 20, // Get more to have better random selection
      );

      if (banners.isEmpty) return null;

      // Return random banner
      final random = Random();
      final randomIndex = random.nextInt(banners.length);
      return banners[randomIndex];
    } catch (e) {
      print('Error fetching random banner: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getHomeBanners() async {
    return getBanners(
      position: 'top',
      pageScope: 'search', // Home page scope
      limit: 5,
    );
  }

  static Future<Map<String, dynamic>?> getHomeBanner() async {
    return getRandomBanner(
      position: 'top',
      pageScope: 'search', // Home page scope
    );
  }

  static Future<Map<String, dynamic>?> getAdDetailBanner() async {
    return getRandomBanner(
      position: 'footer',
      pageScope: 'ad', // Ad detail page scope
    );
  }
}
