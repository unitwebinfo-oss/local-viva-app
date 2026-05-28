import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ads_provider.dart';
import '../../models/ad_model.dart';
import '../../utils/theme.dart';
import '../../widgets/ad_card.dart';
import '../ads/ad_detail_screen.dart';

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
  String? _selectedCondition;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCity;
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // Force home reload when going back
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAds() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    
    await adsProvider.fetchAds(
      categoryId: widget.categoryId,
      condition: _selectedCondition,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      city: _selectedCity,
      search: widget.searchQuery,
      refresh: true, // Force refresh to get filtered results
    );
  }

  Future<void> _loadMore() async {
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    if (!adsProvider.isLoading && adsProvider.hasMore) {
      await adsProvider.loadMore(
        categoryId: widget.categoryId,
        condition: _selectedCondition,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        city: _selectedCity,
        search: widget.searchQuery,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
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
              const SizedBox(height: 24),
              
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
              const SizedBox(height: 24),
              
              // Sort by
              const Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('Mais recentes', 'recent', _sortBy),
                  _buildFilterChip('Menor preço', 'price_asc', _sortBy),
                  _buildFilterChip('Maior preço', 'price_desc', _sortBy),
                ],
              ),
              const SizedBox(height: 32),
              
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchAds();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aplicar Filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        title: Text(
          widget.searchQuery != null 
            ? 'Busca: ${widget.searchQuery}'
            : (widget.categoryName ?? 'Anúncios'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
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
                childAspectRatio: 0.55, // Further reduced to prevent overflow
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
