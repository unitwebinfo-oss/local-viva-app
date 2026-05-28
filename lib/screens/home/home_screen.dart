import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/messages_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/ad_card.dart';
import '../../widgets/site_webview.dart';
import '../../widgets/auth_prompt.dart';
import '../../widgets/banner_widget.dart';
import '../../constants/app_constants.dart';
import '../../widgets/brand_logo.dart';
import '../../services/api_service.dart';
import '../../services/banner_service.dart';
import '../../config/api_config.dart';
import '../ads/ad_detail_screen.dart';
import '../ads/create_ad_screen.dart';
import '../ads/my_ads_screen.dart';
import '../profile/profile_screen.dart';
import '../messages/messages_screen.dart';
import '../favorites/favorites_screen.dart';
import '../ads/ads_list_screen.dart';
import '../../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = false;
  bool _isLoadingMore = false;
  Map<String, dynamic>? _homeBanner;

  int? _selectedCategoryId;
  String? _selectedCondition;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCity;
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAds();
      _loadCategories();
      _loadConversations();
      _loadHomeBanner();
    });
    
    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
  }

  
  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCondition = null;
      _minPrice = null;
      _maxPrice = null;
      _selectedCity = null;
      _selectedState = null;
      _searchController.clear();
    });
    // Fetch ads with no filters and force refresh
    _fetchAds(refresh: true);
  }

  void _forceHomeReload() {
    // Complete reset of home state
    setState(() {
      _selectedCategoryId = null;
      _selectedCondition = null;
      _minPrice = null;
      _maxPrice = null;
      _selectedCity = null;
      _selectedState = null;
      _searchController.clear();
    });
    
    // Force provider reset and reload with loading
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    adsProvider.clearFilters();
    
    // Force refresh with loading indicator
    _fetchAds(refresh: true);
    _loadHomeBanner();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreAds();
    }
  }

  void _loadMoreAds() {
    if (!mounted) return;
    
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    if (adsProvider.hasMore && !_isLoadingMore && !adsProvider.isLoading) {
      setState(() => _isLoadingMore = true);
      
      adsProvider.loadMore(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        categoryId: null, // Home always shows all ads
        city: _selectedCity,
        state: _selectedState,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        condition: _selectedCondition,
      ).then((_) {
        if (mounted) setState(() => _isLoadingMore = false);
      });
    }
  }

  void _onSearch() {
    // Navigate to ads listing screen with search query
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdsListScreen(
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryId != null 
            ? _categories.firstWhere((c) => c['id'] == _selectedCategoryId, orElse: () => {'name': 'Categoria'})['name']
            : null,
        ),
      ),
    );
  }

  Future<void> _loadConversations() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    await context.read<MessagesProvider>().fetchConversations(userId: auth.user?.id);
  }

  Future<void> _loadHomeBanner() async {
    try {
      print('DEBUG: Loading home banner...');
      final banner = await BannerService.getHomeBanner();
      print('DEBUG: Home banner loaded: $banner');
      if (mounted) {
        setState(() {
          _homeBanner = banner;
        });
        print('DEBUG: Home banner state updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading home banner: $e');
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });

    try {
      final response = await ApiService.get(ApiConfig.categories);
      if (response['success'] == true) {
        final List<Map<String, dynamic>> list = [];
        
        // Load only main categories (first level only)
        if (response['categories'] is List) {
          for (final node in response['categories']) {
            list.add({
              'id': node['id'],
              'name': node['name'],
              'icon': node['icon'],
            });
          }
        }

        setState(() {
          // Show only first 8 main categories
          _categories = list.take(8).toList();
        });
      }
    } catch (e) {
      // ignore for now; filters will show fallback state
    } finally {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  void _openFiltersSheet() {
    final TextEditingController minPriceCtrl =
        TextEditingController(text: _minPrice?.toString() ?? '');
    final TextEditingController maxPriceCtrl =
        TextEditingController(text: _maxPrice?.toString() ?? '');
    if (_selectedCity != null) {
      final locationDisplay = _selectedState != null
          ? '${_selectedCity!}, ${_selectedState!}'
          : _selectedCity!;
      _locationController.text = locationDisplay;
    } else {
      _locationController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros',
                        style: AppTextStyles.heading2,
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategoryId = null;
                            _selectedCondition = null;
                            _minPrice = null;
                            _maxPrice = null;
                            _selectedCity = null;
                            _selectedState = null;
                            minPriceCtrl.clear();
                            maxPriceCtrl.clear();
                            _locationController.clear();
                          });
                        },
                        child: const Text('Limpar filtros'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Localização (Cidade, UF)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        hint: _loadingCategories
                            ? const Text('Carregando...')
                            : const Text('Todas as categorias'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas as categorias'),
                          ),
                          ..._categories.map(
                            (cat) => DropdownMenuItem<int?>(
                              value: cat['id'] as int?,
                              child: Text(cat['name'] as String),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Preço mínimo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Preço máximo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Condição',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCondition,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todas')),
                          DropdownMenuItem(value: 'new', child: Text('Novo')),
                          DropdownMenuItem(value: 'used', child: Text('Usado')),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            _selectedCondition = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = minPriceCtrl.text.isNotEmpty
                              ? double.tryParse(minPriceCtrl.text)
                              : null;
                          _maxPrice = maxPriceCtrl.text.isNotEmpty
                              ? double.tryParse(maxPriceCtrl.text)
                              : null;
                          _parseLocationInput(_locationController.text);
                        });
                        _applyFilters();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _parseLocationInput(String input) {
    if (input.trim().isEmpty) {
      _selectedCity = null;
      _selectedState = null;
      return;
    }

    final parts = input.split(',');
    if (parts.length == 2) {
      _selectedCity = parts[0].trim();
      final statePart = parts[1].trim().toUpperCase();
      _selectedState = statePart.length == 2 ? statePart : null;
    } else {
      _selectedCity = input.trim();
      _selectedState = null;
    }
  }

  void _applyFilters() {
    _fetchAds();
  }

  Future<void> _fetchAds({bool refresh = true}) {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final searchText = _searchController.text.trim();

    return adsProvider.fetchAds(
      refresh: refresh,
      categoryId: null, // Home always shows all ads
      city: _selectedCity,
      state: _selectedState,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      condition: _selectedCondition,
      search: searchText.isNotEmpty ? searchText : null,
    );
  }

  Future<void> _loadMoreAdsForProvider(AdsProvider adsProvider) {
    final searchText = _searchController.text.trim();
    return adsProvider.loadMore(
      categoryId: null, // Home always shows all ads
      city: _selectedCity,
      state: _selectedState,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      condition: _selectedCondition,
      search: searchText.isNotEmpty ? searchText : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const BrandLogo(height: 40),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<MessagesProvider>(
            builder: (context, messagesProvider, child) {
              final unreadCount = messagesProvider.conversations
                  .fold(0, (sum, conv) => sum + conv.unreadCount);
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MessagesScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textSecondary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      body: _buildHomeFeed(),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(height: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Local Viva',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.of(context).pop();
                // Refresh home data
                _fetchAds();
                _loadHomeBanner();
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favoritos'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToScreen('Favoritos', 'favorites', auth);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Anunciar'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToScreen('Anunciar', 'create_ad', auth);
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Meus Anúncios'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToScreen('Meus Anúncios', 'my_ads', auth);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Mensagens'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToScreen('Mensagens', 'messages', auth);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToScreen('Perfil', 'profile', auth);
              },
            ),
            const Divider(),
            if (!auth.isAuthenticated)
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.primary),
                title: const Text('Fazer Login'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/login');
                },
              ),
            if (auth.isAuthenticated)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.read<AuthProvider>().logout();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(String title, String screenType, AuthProvider auth) async {
    // Only require auth for user-specific features
    final requiresAuth = ['create_ad', 'my_ads', 'profile', 'messages'].contains(screenType);
    
    if (requiresAuth && !auth.isAuthenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Faça login para acessar $title',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Entrando você consegue gerenciar anúncios, mensagens e muito mais.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context, rootNavigator: true).pushNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Fazer login'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
      return;
    }

    // Check ad limit before navigating to create_ad screen
    if (screenType == 'create_ad') {
      await _checkAdLimitBeforeCreate();
      return;
    }

    Widget screen;
    switch (screenType) {
      case 'create_ad':
        screen = const CreateAdScreen();
        break;
      case 'my_ads':
        screen = const MyAdsScreen();
        break;
      case 'profile':
        screen = const ProfileScreen();
        break;
      case 'messages':
        screen = const MessagesScreen();
        break;
      case 'favorites':
        screen = const FavoritesScreen();
        break;
      default:
        screen = const SizedBox.shrink();
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildHomeFeed() {
    return Column(
      children: [
        // Fixed Header and Search
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onSubmitted: (_) {
                  final searchText = _searchController.text.trim();
                  if (searchText.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdsListScreen(
                          categoryId: null, // Search shows all ads
                          categoryName: null,
                          searchQuery: searchText,
                        ),
                      ),
                    );
                  }
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar anúncios...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.tune, color: Colors.white70),
                        if (_hasActiveFilters)
                          const Positioned(
                            right: -2,
                            top: -2,
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: AppColors.accent,
                            ),
                          ),
                      ],
                    ),
                    onPressed: _openFiltersSheet,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Scrollable content
        Expanded(
          child: Consumer<AdsProvider>(
            builder: (context, adsProvider, child) {
              return RefreshIndicator(
                onRefresh: () async {
                  await _fetchAds();
                  await _loadHomeBanner();
                },
                child: CustomScrollView(
                  slivers: [
                  // Home Banner
                  if (_homeBanner != null)
                    SliverToBoxAdapter(
                      child: BannerWidget(
                        imageUrl: _homeBanner!['image_url'],
                        linkUrl: _homeBanner!['link_url'],
                        title: _homeBanner!['title'] ?? 'Banner',
                        fullWidth: true,
                      ),
                    ),
                  // Categories section
                  if (_categories.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Categorias em destaque',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 12),
                              child: CategoryCard(
                                id: category['id'],
                                name: category['name'],
                                icon: category['icon'],
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdsListScreen(
                                        categoryId: category['id'],
                                        categoryName: category['name'],
                                      ),
                                    ),
                                  );
                                  // Force reload when returning from category screen
                                  if (mounted) {
                                    _forceHomeReload();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                  ],
                  // Ads list
                  if (adsProvider.isLoading && adsProvider.ads.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (adsProvider.error != null && adsProvider.ads.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar anúncios',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              adsProvider.error ?? '',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                adsProvider.fetchAds(refresh: true);
                              },
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (adsProvider.ads.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('Nenhum anúncio encontrado'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: _getResponsiveGridDelegate(),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Load more when reaching near the end
                            if (index >= adsProvider.ads.length - 3 && 
                                !_isLoadingMore && 
                                adsProvider.hasMore) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  _loadMoreAds();
                                }
                              });
                            }
                            
                            if (index == adsProvider.ads.length && _isLoadingMore) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            final ad = adsProvider.ads[index];
                            return AdCard(
                              ad: ad,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AdDetailScreen(adId: ad.id),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: adsProvider.ads.length + (_isLoadingMore ? 1 : 0),
                        ),
                      ),
                    ),
                ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _getResponsiveGridDelegate() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      // Desktop - 6 columns
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      );
    } else if (screenWidth >= 900) {
      // Large tablet - 4 columns
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      );
    } else if (screenWidth >= 600) {
      // Small tablet - 3 columns
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      );
    } else {
      // Mobile - 2 columns (iPhone 12 Pro, Galaxy S8, Galaxy Z Fold, etc)
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.56,
      );
    }
  }

  Future<void> _checkAdLimitBeforeCreate() async {
    try {
      if (kDebugMode) {
        print('=== CHECKING AD LIMIT BEFORE CREATE ===');
      }
      
      // Check user's ad package and usage
      final response = await ApiService.get(ApiConfig.userPackage);
      
      if (kDebugMode) {
        print('User package response: $response');
      }
      
      if (response['success'] == true) {
        final canCreate = response['canCreate'] ?? true;
        final usageInfo = response['usage'] ?? {};
        final current = usageInfo['used'] ?? 0;
        final limit = usageInfo['limit'] ?? 5;
        final remaining = usageInfo['remaining'] ?? (limit - current);
        
        if (kDebugMode) {
          print('Can create: $canCreate, Current: $current, Limit: $limit, Remaining: $remaining');
        }
        
        if (!canCreate || remaining <= 0) {
          // Show limit reached dialog ONLY when limit is reached
          _showAdLimitDialog(current, limit, false);
          return;
        } else {
          // Go directly to create ad screen when user has space
          if (kDebugMode) {
            print('User has space available, going directly to create ad screen');
          }
          _navigateToCreateAdScreen();
          return;
        }
      } else {
        if (kDebugMode) {
          print('API response failed, allowing creation as fallback');
        }
        // Fallback: allow creation
        _navigateToCreateAdScreen();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking ad limit: $e, allowing creation as fallback');
      }
      // If there's an error, allow creation
      _navigateToCreateAdScreen();
    }
  }

  void _showAdLimitDialog(int current, int limit, bool canCreate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              canCreate ? Icons.check_circle_outline : Icons.warning_outlined,
              size: 64,
              color: canCreate ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              canCreate ? 'Limite de Anúncios' : 'Limite Atingido',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canCreate 
                ? 'Você pode criar mais ${limit - current} anúncio(s)'
                : 'Você atingiu seu limite de $limit anúncios',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Anúncios ativos: $current/$limit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (canCreate) {
                    _navigateToCreateAdScreen();
                  }
                  // If can't create, just close dialog - don't open screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: canCreate ? AppColors.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(canCreate ? 'Criar Anúncio' : 'Fechar'),
              ),
            ),
            if (!canCreate) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to packages page on website
                    _openPackagesPage();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Ver Planos'),
                ),
              ),
              const SizedBox(height: 20), // Add padding at bottom
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToCreateAdScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateAdScreen()),
    );
  }

  void _openPackagesPage() async {
    // Open packages page in new window/tab
    final url = Uri.parse('https://localviva.com.br/pacotes');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visite: https://localviva.com.br/pacotes'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  bool get _hasActiveFilters {
    return _selectedCategoryId != null ||
        _selectedCondition != null ||
        _minPrice != null ||
        _maxPrice != null ||
        _selectedCity != null ||
        _selectedState != null;
  }
}
