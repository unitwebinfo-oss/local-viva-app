import 'package:flutter/foundation.dart';
import '../models/ad_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class FavoritesProvider with ChangeNotifier {
  List<AdModel> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<AdModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFavorites({int? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = ApiConfig.favorites;
      if (userId != null) {
        url += '?user_id=$userId';
      }
      
      if (kDebugMode) {
        print('Fetching favorites from: $url');
      }
      
      final response = await ApiService.get(url);
      
      if (kDebugMode) {
        print('Favorites response: $response');
      }

      if (response['success'] == true) {
        _favorites = (response['favorites'] as List)
            .map((json) => AdModel.fromFavoriteJson(json))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(int adId, {int? userId}) async {
    try {
      final isFavorited = _favorites.any((ad) => ad.id == adId);

      if (kDebugMode) {
        print('Toggling favorite for ad $adId: ${isFavorited ? 'remove' : 'add'}');
      }

      Map<String, dynamic> data = {'ad_id': adId};
      
      if (userId != null) {
        data['user_id'] = userId;
      }

      if (isFavorited) {
        // Remove favorite
        final response = await ApiService.delete('${ApiConfig.favorites}/$adId', data: data);
        
        if (response['success'] == true) {
          _favorites.removeWhere((ad) => ad.id == adId);
          notifyListeners();
          return true;
        } else {
          _error = response['error'] ?? 'Erro ao remover favorito';
          notifyListeners();
          return false;
        }
      } else {
        // Add favorite
        final response = await ApiService.post(ApiConfig.favorites, data);
        
        if (response['success'] == true) {
          // Refresh favorites to get the complete ad data with favorited_at timestamp
          await fetchFavorites(userId: userId);
          return true;
        } else {
          _error = response['error'] ?? 'Erro ao adicionar favorito';
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error toggling favorite: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool isFavorited(int adId) {
    return _favorites.any((ad) => ad.id == adId);
  }
}
