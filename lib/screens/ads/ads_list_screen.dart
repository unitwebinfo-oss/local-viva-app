import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ads_provider.dart';
import '../../models/ad_model.dart';
import '../../utils/theme.dart';
import '../../widgets/ad_card.dart';
import '../ads/ad_detail_screen.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class AdsListScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  final String? searchQuery;

  const AdsListScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.searchQuery,
  });

  @override
  State<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _selectedCondition;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCity;
  String? _selectedState;
  String _sortBy = 'recent';
  bool _isSearching = false;

  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _subcategories = [];
  int? _selectedMainCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
    }
    if (widget.categoryId != null) {
      _selectedCategoryId = widget.categoryId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _fetchAds();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.get(ApiConfig.categories);
      if (response['success'] == true && response['categories'] is List) {
        setState(() {
          _allCategories = (response['categories'] as List)
              .map((c) => {
                    'id': c['id'],
                    'name': c['name'],
                    'parent_id': c['parent_id'],
                  })
              .toList()
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchAds() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final searchText = _searchController.text.trim();
    
    await adsProvider.fetchAds(
      categoryId: _selectedCategoryId ?? widget.categoryId,
      condition: _selectedCondition,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      city: _selectedCity,
      state: _selectedState,
      search: searchText.isNotEmpty ? searchText : null,
      sort: _sortBy,
      refresh: true,
    );
  }

  Future<void> _loadMore() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    if (!adsProvider.isLoading && adsProvider.hasMore) {
      final searchText = _searchController.text.trim();
      await adsProvider.loadMore(
        categoryId: _selectedCategoryId ?? widget.categoryId,
        condition: _selectedCondition,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        city: _selectedCity,
        state: _selectedState,
        search: searchText.isNotEmpty ? searchText : null,
        sort: _sortBy,
      );
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersSheet(),
    );
  }

  Widget _buildFiltersSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
              
              // Category filter
              if (_allCategories.isNotEmpty) ...[
                const Text(
                  'Categoria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedMainCategoryId,
                      isExpanded: true,
                      hint: const Text('Todas as categorias'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas as categorias'),
                        ),
                        ..._allCategories
                            .where((c) => c['parent_id'] == null || c['parent_id'] == 0)
                            .map(
                              (cat) => DropdownMenuItem<int?>(
                                value: cat['id'] as int?,
                                child: Text(cat['name'] as String),
                              ),
                            ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _selectedMainCategoryId = value;
                          _selectedSubcategoryId = null;
                          if (value != null) {
                            _subcategories = _allCategories
                                .where((c) => c['parent_id'] == value)
                                .toList();
                          } else {
                            _subcategories = [];
                          }
                        });
                      },
                    ),
                  ),
                ),
                if (_subcategories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedSubcategoryId,
                        isExpanded: true,
                        hint: const Text('Subcategoria'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas as subcategorias'),
                          ),
                          ..._subcategories.map(
                            (cat) => DropdownMenuItem<int?>(
                              value: cat['id'] as int?,
                              child: Text(cat['name'] as String),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            _selectedSubcategoryId = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Condition filter
              const Text(
                'Condição',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('Todos', null, _selectedCondition),
                  _buildFilterChip('Novo', 'new', _selectedCondition),
                  _buildFilterChip('Usado', 'used', _selectedCondition),
                ],
              ),
              const SizedBox(height: 16),

              // Estado
              const Text(
                'Estado',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedState,
                    isExpanded: true,
                    hint: const Text('Todos os estados'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos os estados'),
                      ),
                      ...['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO']
                          .map((uf) => DropdownMenuItem<String?>(
                                value: uf,
                                child: Text(uf),
                              )),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedState = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cidade
              const Text(
                'Cidade ou bairro',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Digite a cidade',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  setModalState(() {
                    _selectedCity = value.isNotEmpty ? value : null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Price range
              const Text(
                'Faixa de Preço',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Mínimo',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _minPrice = double.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Máximo',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxPrice = double.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sort by
              const Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('Mais recentes', 'recent', _sortBy),
                  _buildFilterChip('Menor preço', 'price_asc', _sortBy),
                  _buildFilterChip('Maior preço', 'price_desc', _sortBy),
                ],
              ),
              const SizedBox(height: 20),
              
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _selectedCategoryId = _selectedSubcategoryId ?? _selectedMainCategoryId;
                    Navigator.pop(context);
                    _fetchAds();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aplicar Filtros',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildFilterChip(String label, String? value, String? currentValue) {
    final isSelected = value == currentValue;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (label == 'Todos' || label == 'Mais recentes' || label == 'Menor preço' || label == 'Maior preço') {
            if (label.contains('preço') || label == 'Mais recentes') {
              _sortBy = value ?? 'recent';
            } else {
              _selectedCondition = null;
            }
          } else {
            _selectedCondition = value;
          }
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: widget.searchQuery != null && widget.searchQuery!.isNotEmpty,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar em ${widget.categoryName ?? 'todos'}...',
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _fetchAds();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onSubmitted: (_) => _fetchAds(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilters,
            ),
          ],
        ),
      body: Consumer<AdsProvider>(
        builder: (context, adsProvider, child) {
          if (adsProvider.isLoading && adsProvider.ads.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (adsProvider.error != null && adsProvider.ads.isEmpty) {
            return Center(
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
                    adsProvider.error!,
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchAds,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (adsProvider.ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum anúncio encontrado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tente ajustar os filtros',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchAds,
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: adsProvider.ads.length + (adsProvider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == adsProvider.ads.length) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdDetailScreen(adId: ad.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }
}
