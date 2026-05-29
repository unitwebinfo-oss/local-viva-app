import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/ad_card.dart';
import '../../utils/auth_helpers.dart';
import '../ads/ad_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    await context.read<FavoritesProvider>().fetchFavorites(userId: auth.user?.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAuthModal(context, featureName: 'Favoritos');
      });
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
            ),
          ),
          elevation: 0,
          title: const Text('Favoritos'),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: true,
        ),
        body: const _EmptyState(
          title: 'Entre para ver seus favoritos',
          description: 'Salve os anúncios que você mais gosta para acessá-los depois.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
        ),
        elevation: 0,
        title: const Text('Favoritos'),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading && favoritesProvider.favorites.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoritesProvider.error != null &&
              favoritesProvider.favorites.isEmpty) {
            return _ErrorState(
              message: favoritesProvider.error!,
              onRetry: _loadFavorites,
            );
          }

          if (favoritesProvider.favorites.isEmpty) {
            return const _EmptyState(
              title: 'Nada por aqui ainda',
              description:
                  'Toque no coração dos anúncios para salvá-los nesta lista.',
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFavorites,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: favoritesProvider.favorites.length,
                itemBuilder: (context, index) {
                  final ad = favoritesProvider.favorites[index];
                  return AdCard(
                    ad: ad,
                    showFavorite: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdDetailScreen(adId: ad.id),
                        ),
                      );
                    },
                    onFavorite: () async {
                      final auth = context.read<AuthProvider>();
                      await context.read<FavoritesProvider>().toggleFavorite(ad.id, userId: auth.user?.id);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Erro ao carregar favoritos', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String description;

  const _EmptyState({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_outline,
                size: 72, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
