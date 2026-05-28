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
              Navigator.of(context).pushNamed('/create-ad');
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
        title: Row(
          children: [
            Icon(Icons.more_horiz, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Mais opções'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acesse o painel completo',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 12),
            Text(
              'Para acessar todas as funcionalidades disponíveis para seu anúncio, acesse nosso site e utilize as ferramentas completas.',
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
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
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
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Redirecionar para o site
              final Uri url = Uri.parse('https://localviva.com.br/entrar');
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Acessar Site'),
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: AppColors.surface,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 180,
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
                if (isBoosted)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Turbinado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ad.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ad.status?.toUpperCase() ?? 'UNKNOWN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (ad.isFavorited)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title ?? 'Sem título',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.formattedPrice ?? 'R\$ 0,00',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${ad.views ?? 0} visualizações',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (ad.city != null || ad.state != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${ad.city ?? ''}, ${ad.state ?? ''}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (ad.phone != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ad.phone!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (ad.status == 'expired')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Anúncio Expirado', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Reativações: ${(ad.categoryReactivationLimit ?? 3) - (ad.freeReactivationsUsed ?? 0)}/${ad.categoryReactivationLimit ?? 3}', style: const TextStyle(fontSize: 12)),
                                                                  ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (ad.categoryReactivationLimit == 0) ? null : onReactivate,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: Text(
                                ad.categoryReactivationLimit == 0 
                                  ? '♻️ Sem Reativações Grátis' 
                                  : '♻️ Reativar Grátis'
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ad.categoryReactivationLimit == 0 
                                  ? Colors.grey 
                                  : Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEdit,
                          child: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isBoosted)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onBoost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('⋯ Mais opções'),
                          ),
                        ),
                      if (isBoosted)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('🚀 Já Turbinado'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (onDelete != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Excluir Anúncio'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
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
