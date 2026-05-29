import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/ad_model.dart';
import '../ads/ad_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<AdModel> _myAds = [];
  bool _isLoadingAds = false;

  @override
  void initState() {
    super.initState();
    _loadMyAds();
  }

  Future<void> _loadMyAds() async {
    setState(() => _isLoadingAds = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        setState(() => _isLoadingAds = false);
        return;
      }
      final currentUserId = authProvider.user!.id;
      final url = '${ApiConfig.ads}?user_id=$currentUserId';
      final response = await ApiService.get(url);
      if (response['success'] == true && response['ads'] is List) {
        final ads = (response['ads'] as List)
            .map((json) => AdModel.fromJson(json))
            .toList();
        ads.sort((a, b) => b.views.compareTo(a.views));
        setState(() => _myAds = ads);
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar anúncios: $e');
    } finally {
      setState(() => _isLoadingAds = false);
    }
  }

  int get _totalAds => _myAds.length;
  int get _activeAds => _myAds.where((a) => a.status == 'active').length;
  int get _totalViews => _myAds.fold(0, (sum, a) => sum + a.views);
  int get _totalClicks => _myAds.fold(0, (sum, a) => sum + a.whatsappClicks);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: auth.user == null
          ? const Center(child: Text('Usuário não encontrado'))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(auth.user!)),
                SliverToBoxAdapter(child: _buildStatsCards()),
                SliverToBoxAdapter(child: _buildTopAdsSection()),
                SliverToBoxAdapter(child: _buildActionsSection()),
                SliverToBoxAdapter(child: _buildPersonalInfo(auth.user!)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top bar with back button
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            user.email,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          // Verified badge
          if (user.emailVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: Colors.greenAccent),
                  SizedBox(width: 4),
                  Text(
                    'Conta verificada',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Painel de Análise',
                style: AppTextStyles.heading3.copyWith(fontSize: 18),
              ),
              if (_isLoadingAds)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Anúncios', _totalAds.toString(), Icons.list_alt, const Color(0xFF0F766E))),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Ativos', _activeAds.toString(), Icons.check_circle, const Color(0xFF15803D))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statCard('Visualizações', _formatNumber(_totalViews), Icons.visibility, const Color(0xFF0369A1))),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Cliques Whats', _formatNumber(_totalClicks), Icons.chat_bubble, const Color(0xFF7C3AED))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  Widget _buildTopAdsSection() {
    if (_myAds.isEmpty) return const SizedBox.shrink();

    final topAds = _myAds.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Anúncios', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/my_ads'),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...topAds.map((ad) => _buildAdPerformanceCard(ad)),
        ],
      ),
    );
  }

  Widget _buildAdPerformanceCard(AdModel ad) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdDetailScreen(adId: ad.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ad.primaryImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ad.primaryImageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.formattedPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _miniStat(Icons.visibility, ad.views.toString(), const Color(0xFF0369A1)),
                      const SizedBox(width: 12),
                      _miniStat(Icons.chat_bubble, ad.whatsappClicks.toString(), const Color(0xFF7C3AED)),
                    ],
                  ),
                ],
              ),
            ),
            _statusBadge(ad.status),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statusBadge(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = const Color(0xFF15803D);
        label = 'Ativo';
        break;
      case 'pending':
        color = const Color(0xFFA16207);
        label = 'Pendente';
        break;
      case 'expired':
        color = const Color(0xFF6B7280);
        label = 'Expirado';
        break;
      default:
        color = const Color(0xFF6B7280);
        label = status ?? 'Desconhecido';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ações Rápidas', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _actionChip(Icons.add_circle, 'Criar Anúncio', () {
                Navigator.of(context).pushNamed('/create_ad');
              }),
              _actionChip(Icons.list_alt, 'Meus Anúncios', () {
                Navigator.of(context).pushNamed('/my_ads');
              }),
              _actionChip(Icons.favorite, 'Favoritos', () {
                Navigator.of(context).pushNamed('/favorites');
              }),
              _actionChip(Icons.message, 'Mensagens', () {
                Navigator.of(context).pushNamed('/messages');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(dynamic user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações Pessoais', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            _infoTile(Icons.person_outline, 'Nome', user.name),
            if (user.phone != null && user.phone!.isNotEmpty)
              _infoTile(Icons.phone_outlined, 'Telefone', user.phone!),
            _infoTile(Icons.email_outlined, 'Email', user.email),
            if (user.cpf != null && user.cpf!.isNotEmpty)
              _infoTile(Icons.badge_outlined, 'CPF', user.cpf!),
            if (user.city != null && user.city!.isNotEmpty)
              _infoTile(Icons.location_on_outlined, 'Localização',
                  '${user.city}${user.stateUf != null ? ' - ${user.stateUf}' : ''}'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildExternalActionTile(
              icon: Icons.edit,
              label: 'Editar Perfil',
              onTap: () => _redirectToWebsite('perfil'),
            ),
            _buildExternalActionTile(
              icon: Icons.lock_outline,
              label: 'Alterar Senha',
              onTap: () => _redirectToWebsite('senha'),
            ),
            _buildExternalActionTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Política de Privacidade',
              onTap: () => _redirectToWebsite('privacidade'),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Excluir Conta', style: TextStyle(color: AppColors.error)),
              onTap: () => _redirectToWebsite('excluir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  void _redirectToWebsite(String action) async {
    String url = 'https://localviva.com.br/entrar';
    switch (action) {
      case 'perfil':
      case 'senha':
      case 'excluir':
        url = 'https://localviva.com.br/entrar';
        break;
      case 'privacidade':
        url = 'https://localviva.com.br/privacidade';
        break;
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visite: $url'), duration: const Duration(seconds: 5)),
        );
      }
    }
  }
}
