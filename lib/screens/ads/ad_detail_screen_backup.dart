import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/ad_model.dart';
import '../../utils/theme.dart';
import '../../utils/string_extension.dart';
import '../../widgets/banner_widget.dart';
import '../../services/banner_service.dart';
import '../../config/api_config.dart';

class AdDetailScreen extends StatefulWidget {
  final int adId;

  const AdDetailScreen({super.key, required this.adId});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  AdModel? _ad;
  bool _isLoading = true;
  Map<String, dynamic>? _adDetailBanner;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _preloadImages() {
    if (_ad != null && _ad!.images.isNotEmpty) {
      for (final imageUrl in _ad!.images) {
        precacheImage(CachedNetworkImageProvider(imageUrl), context);
      }
    }
  }

  Future<void> _loadAd() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final ad = await adsProvider.getAdById(widget.adId);
    
    if (mounted) {
      setState(() {
        _ad = ad;
        _isLoading = false;
      });
      // Preload all images after ad is loaded
      _preloadImages();
      // Load ad detail banner
      _loadAdDetailBanner();
    }
  }

  Future<void> _loadAdDetailBanner() async {
    try {
      final banner = await BannerService.getAdDetailBanner();
      if (mounted) {
        setState(() {
          _adDetailBanner = banner;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ad detail banner: $e');
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    // Try phone field first, then sellerPhone as fallback
    final phoneNumber = _ad?.phone ?? _ad?.sellerPhone;
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    
    final phone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final message = Uri.encodeComponent('Olá, tenho interesse no anúncio: ${_ad!.title}');
    final url = Uri.parse('https://wa.me/55$phone?text=$message');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_ad == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Anúncio não encontrado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _ad!.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: _ad!.images.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: _ad!.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                          // Preload next and previous images
                          memCacheHeight: 800,
                          memCacheWidth: 600,
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 64),
                    ),
            ),
            actions: [
              Consumer<FavoritesProvider>(
                builder: (context, favProvider, child) {
                  final isFavorited = favProvider.isFavorited(_ad!.id);
                  return IconButton(
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_outline,
                      color: isFavorited ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      favProvider.toggleFavorite(_ad!.id, userId: auth.user?.id);
                    },
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ad!.title.toLowerCase().capitalizeFirst(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _ad!.formattedPrice,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (_ad!.negotiable)
                    const Text(
                      'Preço negociável',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Descrição',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ad!.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Informações',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Categoria', _ad!.categoryName ?? 'Não informada'),
                  _buildInfoRow('Localização', _ad!.location),
                  if (_ad!.conditionType != null && _ad!.conditionType != 'not_applicable')
                    _buildInfoRow(
                      'Condição',
                      _ad!.conditionType == 'new' ? 'Novo' : 'Usado',
                    ),
                  // Views removed - only shown in My Ads
                  const SizedBox(height: 24),
                  if (_ad!.sellerName != null) ...[
                    const Text(
                      'Vendedor',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            _ad!.sellerName![0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _ad!.sellerName!,
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  ),
  bottomNavigationBar: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: SafeArea(
      child: ElevatedButton.icon(
        onPressed: _launchWhatsApp,
        icon: const Icon(Icons.chat),
        label: const Text('Entrar em contato'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
