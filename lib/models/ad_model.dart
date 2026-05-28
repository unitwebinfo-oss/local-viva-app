import '../config/api_config.dart';

class AdModel {
  final int id;
  final String title;
  final String description;
  final double price;
  final bool negotiable;
  final String? conditionType;
  final String? city;
  final String? state;
  final String? categoryName;
  final String? parentCategoryName;
  final String? primaryImagePath;
  final String? primaryImageUrl;
  final List<String> images;
  final String? sellerName;
  final String? sellerPhone;
  final int views;
  final String? createdAt;
  final bool isFavorited;
  final String? favoritedAt;
  final String? boostType;
  final String? boostExpiresAt;
  final String? status;
  final int categoryId;
  final String? cep;
  final String? neighborhood;
  final String? address;
  final String? phone;
  final int freeReactivationsUsed;
  final int? categoryReactivationLimit;

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.negotiable,
    this.conditionType,
    this.city,
    this.state,
    required this.categoryName,
    this.parentCategoryName,
    this.primaryImagePath,
    this.primaryImageUrl,
    this.images = const [],
    this.sellerName,
    this.sellerPhone,
    required this.views,
    required this.createdAt,
    this.isFavorited = false,
    this.favoritedAt,
    this.boostType = 'none',
    this.boostExpiresAt,
    this.status,
    required this.categoryId,
    this.cep,
    this.neighborhood,
    this.address,
    this.phone,
    this.freeReactivationsUsed = 0,
    this.categoryReactivationLimit,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    final primaryPath = json['primary_image'] ?? json['primary_image_path'];
    final primaryUrl = _normalizeImageUrl(primaryPath);
    
    List<String> imageUrls = [];
    if (json['images'] is List) {
      imageUrls = (json['images'] as List)
          .map((img) => img is String ? img : img['image_path']?.toString() ?? '')
          .map(_normalizeImageUrl)
          .whereType<String>()
          .toList();
    }

    return AdModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      negotiable: json['negotiable'] == 1 || json['negotiable'] == true,
      conditionType: json['condition_type'],
      city: json['city'],
      state: json['state'],
      categoryName: json['category_name'] ?? '',
      parentCategoryName: json['parent_category_name'],
      primaryImagePath: primaryPath,
      primaryImageUrl: primaryUrl,
      images: imageUrls,
      sellerName: json['seller_name'],
      sellerPhone: json['seller_phone'],
      views: json['views'] ?? 0,
      createdAt: json['created_at'],
      isFavorited: json['is_favorited'] ?? false,
      boostType: (json['boost_type'] ?? 'none').toString(),
      boostExpiresAt: json['boost_expires_at'],
      status: json['status'],
      categoryId: json['category_id'] ?? 0,
      cep: json['cep'],
      neighborhood: json['neighborhood'],
      address: json['address'],
      phone: json['phone'],
      freeReactivationsUsed: json['free_reactivations_used'] != null 
        ? int.tryParse(json['free_reactivations_used'].toString()) ?? 0
        : 0,
      categoryReactivationLimit: json['category_reactivation_limit'] != null 
        ? int.tryParse(json['category_reactivation_limit'].toString()) 
        : null
    );
  }

  factory AdModel.fromFavoriteJson(Map<String, dynamic> json) {
    final primaryPath = json['primary_image_path'] ?? json['primary_image'];
    final primaryUrl = _normalizeImageUrl(primaryPath);
    
    return AdModel(
      id: json['ad_id'],
      title: json['title'],
      description: json['description'] ?? '',
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      negotiable: false,
      conditionType: json['condition_type'],
      city: json['city'],
      state: json['state'],
      categoryName: json['category_name'] ?? '',
      parentCategoryName: null,
      primaryImagePath: primaryPath,
      primaryImageUrl: primaryUrl,
      images: primaryUrl != null ? [primaryUrl] : [],
      sellerName: null,
      sellerPhone: null,
      views: 0,
      createdAt: json['created_at'],
      isFavorited: true,
      favoritedAt: json['favorited_at'],
      boostType: 'none',
      boostExpiresAt: null,
      status: json['status'],
      categoryId: 0,
      cep: null,
      neighborhood: null,
      address: null,
      phone: null,
      freeReactivationsUsed: 0,
      categoryReactivationLimit: null
    );
  }

  String get formattedPrice {
    if (price == 0) return 'A consultar';
    final formatted = price.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'R\$ $integerPart,${parts[1]}';
  }

  String get formattedFavoritedDate {
    if (favoritedAt == null) return '';
    final date = DateTime.tryParse(favoritedAt!);
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool get isBoosted {
    if (boostType == 'none' || boostExpiresAt == null) return false;
    final expiry = DateTime.tryParse(boostExpiresAt!);
    if (expiry == null) return false;
    final endOfDay = DateTime(expiry.year, expiry.month, expiry.day, 23, 59, 59);
    return !endOfDay.isBefore(DateTime.now());
  }

  String get boostLabel {
    switch (boostType) {
      case 'super_destaque':
        return 'Super destaque';
      case 'turbo':
        return 'Turbo destaque';
      case 'destaque':
        return 'Plano destaque';
      default:
        return '';
    }
  }

  String get location {
    if (city != null && state != null) {
      return '$city - $state';
    } else if (city != null) {
      return city!;
    } else if (state != null) {
      return state!;
    }
    return 'Localização não informada';
  }

  static String? _normalizeImageUrl(dynamic value) {
    if (value == null) return null;
    String path = value.toString().trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http')) {
      // Convert direct URLs to proxy
      if (path.startsWith(ApiConfig.uploadUrl)) {
        final relativePath = path.replaceFirst(ApiConfig.uploadUrl + '/', '');
        return '${ApiConfig.imageProxyUrl}?path=$relativePath';
      }
      return path;
    }
    path = path.replaceFirst(RegExp(r'^/+'), '');
    return '${ApiConfig.imageProxyUrl}?path=$path';
  }
}
