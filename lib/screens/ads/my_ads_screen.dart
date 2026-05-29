import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/storage_helper.dart';
import '../../models/ad_model.dart';
import '../../widgets/ad_card.dart';
import '../../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/boost_service.dart';
import 'boost_screen.dart';
import '../../config/api_config.dart';
import '../ads/ad_detail_screen.dart';
import 'edit_ad_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  List<AdModel> _myAds = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyAds();
  }

  Future<void> _loadMyAds() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Debug: Check authentication state and token
      final token = await StorageHelper.getToken();
      if (kDebugMode) {
        print('Auth status: ${authProvider.isAuthenticated}');
        print('User ID: ${authProvider.user?.id}');
        print('User name: ${authProvider.user?.name}');
        print('Storage token: $token');
        print('Token is null: ${token == null}');
        print('Token is empty: ${token?.isEmpty ?? true}');
      }
      
      if (!authProvider.isAuthenticated) {
        if (kDebugMode) {
          print('MyAdsScreen: User not authenticated, showing error');
        }
        setState(() {
          _error = 'Usuário não autenticado';
          _isLoading = false;
        });
        return;
      }
      
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('MyAdsScreen: Token is null/empty but user says authenticated - forcing logout');
        }
        await authProvider.logout();
        setState(() {
          _error = 'Sessão expirada. Faça login novamente.';
          _isLoading = false;
        });
        return;
      }

      // Use direct user_id to get user's ads
      final currentUserId = authProvider.user?.id;
      final url = '${ApiConfig.ads}?user_id=$currentUserId';
      if (kDebugMode) {
        print('Loading my ads from: $url');
        print('Full URL being called: $url');
        print('Using direct user_id: $currentUserId');
      }
      
      if (kDebugMode) {
        print('=== CALLING API ===');
        print('URL: $url');
      }
      
      Map<String, dynamic> response;
      
      try {
        response = await ApiService.get(url);
        
        if (kDebugMode) {
          print('=== API RESPONSE ===');
          print('Response: $response');
          print('Success: ${response['success']}');
          print('Has ads key: ${response.containsKey('ads')}');
          print('Response keys: ${response.keys.toList()}');
          if (response.containsKey('ads')) {
            print('Ads type: ${response['ads'].runtimeType}');
            print('Ads length: ${(response['ads'] as List).length}');
          }
          print('HTTP Status: ${ApiService.httpResponse?.statusCode}');
          print('HTTP Headers: ${ApiService.httpResponse?.headers}');
        }
        
        // Debug: Check if this is the fallback response
        if (response.containsKey('pagination')) {
          final pagination = response['pagination'];
          print('Pagination total: ${pagination['total']}');
          if (pagination['total'] == 0) {
            print('*** POSSIBLE AUTHENTICATION ISSUE - Total ads is 0 ***');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('=== API ERROR ===');
          print('Error: $e');
          print('Falling back to all ads due to auth issue');
        }
        
        // Fallback: Get all ads when auth fails
        try {
          response = await ApiService.get('/ads');
          if (kDebugMode) {
            print('=== FALLBACK RESPONSE ===');
            print('Response: $response');
          }
        } catch (fallbackError) {
          if (kDebugMode) {
            print('=== FALLBACK FAILED ===');
            print('Fallback error: $fallbackError');
          }
          rethrow;
        }
      }
      
      if (response['success'] == true) {
        if (kDebugMode) {
          print('=== PROCESSING ADS ===');
          print('Ads data: ${response['ads']}');
          print('Ads type: ${response['ads'].runtimeType}');
          final adsString = response['ads'].toString();
          print('Raw ads data: ${adsString.length > 200 ? adsString.substring(0, 200) + '...' : adsString}');
        }
        
        final List<dynamic> adsData = response['ads'] as List;
        if (kDebugMode) {
          print('Number of ads in response: ${adsData.length}');
          if (adsData.isEmpty) {
            print('WARNING: API returned 0 ads!');
            print('Full response: $response');
          }
        }
        
        // Filter ads by current user ID when using fallback
        final currentUserId = authProvider.user?.id;
        
        if (kDebugMode) {
          print('Current user ID: $currentUserId');
          print('=== ALL ADS DEBUG ===');
          
          // Search for specific test ads
          bool foundTestAds = false;
          for (int i = 0; i < adsData.length; i++) {
            final ad = adsData[i];
            final title = ad['title']?.toString().toLowerCase() ?? '';
            
            if (title.contains('tessexo') || title.contains('2345')) {
              print('*** FOUND TEST AD ***');
              print('Ad ID: ${ad['id']}, User ID: ${ad['user_id']}, Title: ${ad['title']}, Status: ${ad['status']}');
              foundTestAds = true;
            }
            
            if (i < 5) {
              print('Ad ${i+1}: ID=${ad['id']}, User ID=${ad['user_id']}, Title=${ad['title'] ?? 'No title'}');
            }
          }
          
          if (!foundTestAds) {
            print('*** TEST ADS NOT FOUND IN RESPONSE ***');
            print('Searching for: tessexo, 2345');
          }
        }
        
        // Filter ads by current user ID
        if (kDebugMode) {
          print('=== FILTERING BY USER ID ===');
          print('Current user ID: $currentUserId');
        }
        
        final List<AdModel> ads = adsData
            .where((json) {
              // Only include ads from current user
              final adUserId = json['user_id'];
              final matchesUser = adUserId == currentUserId;
              
              if (kDebugMode) {
                print('Ad ID: ${json['id']}, User ID: $adUserId, Status: ${json['status'] ?? 'unknown'}, Matches: $matchesUser');
              }
              
              return matchesUser;
            })
            .map((json) {
              if (kDebugMode) {
                print('Processing ad ID: ${json['id']}, Title: ${json['title'] ?? 'No title'}, Status: ${json['status'] ?? 'unknown'}');
              }
              return AdModel.fromJson(json);
            })
            .toList();
        
        if (kDebugMode) {
          print('=== RESULT ===');
          print('Original ads: ${adsData.length}, User ads: ${ads.length}');
          print('Setting state with ${ads.length} user ads');
          
          if (ads.isNotEmpty) {
            print('User ads:');
            for (final ad in ads) {
              print('  - ID: ${ad.id}, Title: ${ad.title}');
              print('    Category: ${ad.categoryName}');
              print('    City: ${ad.city}, State: ${ad.state}');
              print('    Phone: ${ad.phone}');
              print('    Price: ${ad.price}');
            }
          } else {
            print('No user ads found - this indicates authentication issue');
          }
        }
        
        setState(() {
          _myAds = ads;
          _isLoading = false;
        });
        
        if (kDebugMode) {
          print('State updated. _myAds.length = ${_myAds.length}');
        }
      } else {
        setState(() {
          _error = response['error'] ?? 'Erro ao carregar anúncios';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading my ads: $e');
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _editAd(AdModel ad) async {
    if (ad == null) {
      _showError('Anúncio inválido');
      return;
    }
    
    if (kDebugMode) {
      print('=== EDIT AD DEBUG ===');
      print('Ad ID: ${ad.id}');
      print('Ad Title: ${ad.title}');
      print('Ad Category: ${ad.categoryName}');
      print('Ad Price: ${ad.price}');
      print('Ad Status: ${ad.status}');
      print('Ad City: ${ad.city}');
      print('Ad State: ${ad.state}');
      print('Ad Phone: ${ad.phone}');
      print('Ad Images: ${ad.images}');
      print('Ad Boost Type: ${ad.boostType}');
      print('Ad Views: ${ad.views}');
    }
    
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => EditAdScreen(ad: ad),
        ),
      );
      
      if (result == true) {
        // Ad was updated successfully, refresh the list
        _loadMyAds();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to edit screen: $e');
      }
      _showError('Erro ao abrir tela de edição');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
        ),
        elevation: 0,
        title: const Text('Meus Anúncios'),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar anúncios',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyAds,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_myAds.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMyAds,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myAds.length,
        itemBuilder: (context, index) {
          final ad = _myAds[index];
          return _MyAdCard(
            ad: ad,
            onEdit: () => _editAd(ad),
            onTap: () {
              Navigator.of(context).pushNamed('/ad-detail', arguments: ad);
            },
            onBoost: () => _showBoostDialog(ad),
            onReactivate: () => _reactivateAd(ad),
            onDelete: () => _deleteAd(ad),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum anúncio',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'Você ainda não publicou nenhum anúncio.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/create_ad');
            },
            icon: const Icon(Icons.add),
            label: const Text('Criar Anúncio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showBoostDialog(AdModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Destacar Anúncio'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dê mais visibilidade ao seu anúncio',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 12),
            Text(
              'Para turbinar seu anúncio e aparecer no topo dos resultados, acesse nosso site e escolha um dos planos de destaque.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você será redirecionado para o site Local Viva',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              final Uri url = Uri.parse('https://localviva.com.br/pacotes');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível abrir o site'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Ver Planos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _purchaseBoost(AdModel ad, Map<String, dynamic> plan) async {
    // Navigate directly to boost screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BoostScreen(
          adId: ad.id,
          adTitle: ad.title,
        ),
      ),
    );
    
    // Refresh ads after returning from boost screen
    _loadMyAds();
  }

  void _reactivateAd(AdModel ad) async {
    try {
      final result = await BoostService.reactivateAd(ad.id);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anúncio reativado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMyAds(); // Reload ads to update status
      } else {
        String errorMessage = result['error'] ?? 'Erro ao reativar anúncio';
        
        // Simplified error message for reactivation limit
        if (errorMessage.contains('Limite de reativações gratuitas atingido')) {
          errorMessage = 'Você já usou todas as reativações gratuitas disponíveis. Use um plano boost para manter seu anúncio ativo.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reativar anúncio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteAd(AdModel ad) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Anúncio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tem certeza que deseja excluir este anúncio?'),
              const SizedBox(height: 8),
              Text(
                'Título: ${ad.title}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Esta ação não pode ser desfeita e removerá todos os dados do anúncio.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final result = await BoostService.deleteAd(ad.id);
      
      if (kDebugMode) {
        print('=== DELETE RESPONSE DEBUG ===');
        print('Result: $result');
        print('Success: ${result['success']}');
        print('Error: ${result['error']}');
        print('Status: ${result['status']}');
      }
      
      // Check if ad was actually deleted (even if backend returned error)
      bool adDeleted = false;
      
      if (result['success'] == true) {
        adDeleted = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anúncio excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result['status'] == 500) {
        // Backend returned 500 but ad might have been deleted
        // Force reload to check if ad still exists
        adDeleted = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anúncio excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = result['error'] ?? 'Erro ao excluir anúncio';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Always reload ads to update the list
      if (adDeleted) {
        _loadMyAds(); // Reload ads to update list
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== DELETE EXCEPTION DEBUG ===');
        print('Exception: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao excluir anúncio. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}

class _MyAdCard extends StatelessWidget {
  final AdModel ad;
  final VoidCallback? onEdit;
  final VoidCallback onTap;
  final VoidCallback? onBoost;
  final VoidCallback? onReactivate;
  final VoidCallback? onDelete;

  const _MyAdCard({
    required this.ad,
    this.onEdit,
    required this.onTap,
    this.onBoost,
    this.onReactivate,
    this.onDelete,
  });

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: onTap,
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ad.primaryImageUrl ??
        (ad.images?.isNotEmpty == true ? ad.images!.first : null);
    final bool isBoosted = ad.boostType != 'none' && ad.boostType != null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(
                            height: 160,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (c, u, e) => Container(
                            height: 160,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 160,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                ),
                // Status badge top-right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ad.status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (ad.status ?? 'unknown').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isBoosted)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Destaque',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ad.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.formattedPrice,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${ad.views}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          ad.location,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (ad.status == 'expired')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Expirado - Reativações: ${(ad.categoryReactivationLimit ?? 3) - ad.freeReactivationsUsed}/${ad.categoryReactivationLimit ?? 3}',
                              style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Action chips
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildActionChip(
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        color: AppColors.primary,
                        onTap: onEdit,
                      ),
                      if (ad.status == 'expired' && (ad.categoryReactivationLimit ?? 0) > 0)
                        _buildActionChip(
                          icon: Icons.refresh,
                          label: 'Reativar',
                          color: Colors.orange,
                          onTap: onReactivate,
                        ),
                      if (!isBoosted)
                        _buildActionChip(
                          icon: Icons.rocket_launch_outlined,
                          label: 'Destacar',
                          color: AppColors.primary,
                          onTap: onBoost,
                        ),
                      _buildActionChip(
                        icon: Icons.delete_outline,
                        label: 'Excluir',
                        color: Colors.red,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
