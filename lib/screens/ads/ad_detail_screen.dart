import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/ad_model.dart';
import '../../utils/theme.dart';
import '../../utils/string_extension.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/banner_service.dart';
import '../../widgets/banner_widget.dart';

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
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  List<AdModel> _similarAds = [];
  bool _isLoadingSimilar = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Force home reload when going back
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
    return false;
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
      _preloadImages();
      _loadAdDetailBanner();
      if (ad != null && ad.categoryId != null) {
        _loadSimilarAds(ad.categoryId!);
      }
    }
  }

  Future<void> _loadSimilarAds(int categoryId) async {
    if (_isLoadingSimilar) return;
    setState(() => _isLoadingSimilar = true);

    try {
      final response = await ApiService.get('${ApiConfig.ads}?category_id=$categoryId&limit=20');

      if (mounted && response['success'] == true) {
        final all = (response['ads'] as List)
            .map((json) => AdModel.fromJson(json))
            .where((a) => a.id != widget.adId)
            .take(8)
            .toList();
        setState(() {
          _similarAds = all;
          _isLoadingSimilar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSimilar = false);
      }
    }
  }

  Future<void> _loadAdDetailBanner() async {
    try {
      print('DEBUG: Loading ad detail banner...');
      final banner = await BannerService.getAdDetailBanner();
      print('DEBUG: Ad detail banner loaded: $banner');
      if (mounted) {
        setState(() {
          _adDetailBanner = banner;
        });
        print('DEBUG: Ad detail banner state updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading ad detail banner: $e');
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = _ad?.phone ?? _ad?.sellerPhone;
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    
    final phone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final message = Uri.encodeComponent('Olá, tenho interesse no anúncio: ${_ad!.title}');
    final url = Uri.parse('https://wa.me/55$phone?text=$message');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _shareAd() {
    if (_ad == null) return;
    final text = 'Confira este anúncio no Local Viva: ${_ad!.title} - ${_ad!.formattedPrice}\n'
        'https://localviva.com.br/anuncio/${_ad!.id}';
    Share.share(text);
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: _shareAd,
                ),
              ),
              Consumer<FavoritesProvider>(
                builder: (context, favProvider, child) {
                  final isFavorited = favProvider.isFavorited(_ad!.id);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        await favProvider.toggleFavorite(_ad!.id, userId: auth.user?.id);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _ad!.images.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
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
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                  // Dark gradient at top for button visibility
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Image counter
                  if (_ad!.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _ad!.images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _currentImageIndex == index ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Gradient overlay at bottom for indicator visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ad!.title,
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _ad!.formattedPrice,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_ad!.negotiable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Negociável',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Badges row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_ad!.conditionType != null && _ad!.conditionType != 'not_applicable')
                        _buildBadge(
                          _ad!.conditionType == 'new' ? 'Novo' : 'Usado',
                          _ad!.conditionType == 'new' ? Colors.green : Colors.orange,
                          _ad!.conditionType == 'new' ? Icons.fiber_new : Icons.handshake,
                        ),
                      if (_ad!.isBoosted)
                        _buildBadge(
                          'Destaque',
                          AppColors.primary,
                          Icons.local_fire_department,
                        ),
                      _buildBadge(
                        _ad!.categoryName ?? 'Geral',
                        AppColors.secondary,
                        Icons.category_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Descrição',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ad!.description.toSentenceCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_on_outlined, 'Localização', _ad!.location),
                        if (_ad!.cep != null && _ad!.cep!.isNotEmpty)
                          _buildInfoRow(Icons.map_outlined, 'CEP', _ad!.cep!),
                        _buildInfoRow(Icons.access_time, 'Publicado', _ad!.timeAgo),
                      ],
                    ),
                  ),
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
                    const SizedBox(height: 24),
                  ],
                  // Similar Ads Carousel
                  if (_similarAds.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Anúncios similares',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similarAds.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final ad = _similarAds[index];
                          final imageUrl = ad.primaryImageUrl;
                          return SizedBox(
                            width: 150,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdDetailScreen(adId: ad.id),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 1,
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: AppColors.border,
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: AppColors.border,
                                                child: const Icon(Icons.image, color: AppColors.textSecondary),
                                              ),
                                            )
                                          : Container(
                                              color: AppColors.border,
                                              child: const Icon(Icons.image, color: AppColors.textSecondary),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ad.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ad.formattedPrice,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Ad Detail Banner - Responsive and clickable (always visible)
                  if (_adDetailBanner != null)
                    BannerWidget(
                      imageUrl: _adDetailBanner!['image_url'],
                      linkUrl: _adDetailBanner!['link_url'],
                      title: _adDetailBanner!['title'] ?? 'Banner',
                      fullWidth: true,
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text(
                    'Conversar no WhatsApp',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
