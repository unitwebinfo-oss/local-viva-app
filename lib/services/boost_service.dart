import '../config/api_config.dart';
import '../utils/storage_helper.dart';
import 'api_service.dart';

class BoostService {
  static Future<Map<String, dynamic>> getBoostPlans() async {
    try {
      final endpoint = '/boost';
      print('BOOST DEBUG: Getting plans with endpoint: $endpoint');
      print('BOOST DEBUG: Base URL: ${ApiConfig.baseUrl}');
      final response = await ApiService.get(endpoint);
      print('BOOST DEBUG: Response received: $response');
      return response;
    } catch (e) {
      print('BOOST DEBUG: Error getting boost plans: $e');
      return {'success': false, 'error': 'Erro ao carregar planos'};
    }
  }

  static Future<Map<String, dynamic>> boostAd(int adId, int planId) async {
    try {
      final endpoint = '/boost/boost-ad';
      print('BOOST DEBUG: Boosting ad with endpoint: $endpoint');
      print('BOOST DEBUG: Ad ID: $adId, Plan ID: $planId');
      final response = await ApiService.post(endpoint, {
        'ad_id': adId,
        'plan_id': planId,
      });
      print('BOOST DEBUG: Boost response: $response');
      return response;
    } catch (e) {
      print('BOOST DEBUG: Error boosting ad: $e');
      return {'success': false, 'error': 'Erro ao aplicar boost'};
    }
  }

  static Future<Map<String, dynamic>> reactivateAd(int adId) async {
    try {
      final endpoint = '/boost/reactivate-ad';
      print('BOOST DEBUG: Reactivating ad with endpoint: $endpoint');
      print('BOOST DEBUG: Ad ID: $adId');
      final response = await ApiService.post(endpoint, {
        'ad_id': adId,
      });
      print('BOOST DEBUG: Reactivate response: $response');
      return response;
    } catch (e) {
      print('BOOST DEBUG: Error reactivating ad: $e');
      return {'success': false, 'error': 'Erro ao reativar anúncio'};
    }
  }

  static Future<Map<String, dynamic>> deleteAd(int adId) async {
    try {
      print('DELETE DEBUG: Starting delete for ad ID: $adId');
      final endpoint = '/ads/$adId';
      print('DELETE DEBUG: Endpoint: $endpoint');
      final response = await ApiService.delete(endpoint);
      print('DELETE DEBUG: Response received: $response');
      return response;
    } catch (e) {
      print('DELETE DEBUG: Error deleting ad: $e');
      return {'success': false, 'error': 'Erro ao excluir anúncio'};
    }
  }
}
