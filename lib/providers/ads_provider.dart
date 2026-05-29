import 'package:flutter/foundation.dart';
import '../models/ad_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AdsProvider with ChangeNotifier {
  List<AdModel> _ads = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  List<AdModel> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _totalPages;

  Future<void> fetchAds({
    String? search,
    int? categoryId,
    String? city,
    String? state,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? sort,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _ads = [];
      _totalPages = 1;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': '20',
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        queryParams['q'] = search;
      }
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (city != null) queryParams['cidade'] = city;
      if (state != null) queryParams['estado'] = state;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (condition != null) queryParams['condition'] = condition;
      if (sort != null) queryParams['sort'] = sort;

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Debug: Log the query being sent
      if (kDebugMode) {
        print('Fetching ads with query: ${ApiConfig.ads}?$queryString');
      }

      final response = await ApiService.get('${ApiConfig.ads}?$queryString');

      if (kDebugMode) {
        print('Response: $response');
      }

      if (response['success'] == true) {
        final newAds = (response['ads'] as List)
            .map((json) => AdModel.fromJson(json))
            .toList();

        if (refresh) {
          _ads = newAds;
        } else {
          _ads.addAll(newAds);
        }

        final pagination = response['pagination'];
        _currentPage = pagination['page'];
        _totalPages = pagination['pages'];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore({
    String? search,
    int? categoryId,
    String? city,
    String? state,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? sort,
  }) async {
    if (!hasMore || _isLoading) return;

    _currentPage++;
    await fetchAds(
      search: search,
      categoryId: categoryId,
      city: city,
      state: state,
      minPrice: minPrice,
      maxPrice: maxPrice,
      condition: condition,
      sort: sort,
    );
  }

  Future<void> fetchFeaturedAds({int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('${ApiConfig.ads}?boosted=1&limit=$limit&page=1');

      if (kDebugMode) {
        print('Featured ads response: $response');
      }

      if (response['success'] == true) {
        final featuredAds = (response['ads'] as List)
            .map((json) => AdModel.fromJson(json))
            .toList();

        // Merge featured ads into the main list without duplicates
        final existingIds = _ads.map((a) => a.id).toSet();
        for (final ad in featuredAds) {
          if (!existingIds.contains(ad.id)) {
            _ads.insert(0, ad);
            existingIds.add(ad.id);
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AdModel?> getAdById(int id) async {
    try {
      final queryParams = <String, String>{};
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Debug: Log the query being sent
      if (kDebugMode) {
        print('Fetching ad with query: ${ApiConfig.ads}/$id?$queryString');
      }

      final response = await ApiService.get('${ApiConfig.ads}/$id?$queryString');

      if (kDebugMode) {
        print('Response: $response');
      }

      if (response['success'] == true) {
        return AdModel.fromJson(response['ad']);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  void clearFilters() {
    _ads.clear();
    _currentPage = 1;
    _totalPages = 1;
    _error = null;
    _isLoading = false; // Reset loading state
    notifyListeners();
  }
}
