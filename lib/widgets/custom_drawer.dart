import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../utils/auth_helpers.dart';
import '../widgets/brand_logo.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(height: 32),
                  const SizedBox(height: 20),
                  Text(
                    auth.isAuthenticated ? (user?.name ?? 'Usuário') : 'Visitante',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.isAuthenticated ? (user?.email ?? '') : 'Faça login para mais recursos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (auth.isAuthenticated && (user?.emailVerified ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 12, color: Colors.greenAccent),
                            SizedBox(width: 4),
                            Text(
                              'Conta verificada',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _menuItem(
                    context: context,
                    icon: Icons.home_outlined,
                    label: 'Início',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                    },
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.favorite_outline,
                    label: 'Favoritos',
                    onTap: () => _navigate(context, 'Favoritos', 'favorites', auth),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Divider(height: 1),
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.add_circle_outline,
                    label: 'Anunciar',
                    color: AppColors.primary,
                    onTap: () => _navigate(context, 'Anunciar', 'create_ad', auth),
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.article_outlined,
                    label: 'Meus Anúncios',
                    onTap: () => _navigate(context, 'Meus Anúncios', 'my_ads', auth),
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    label: 'Mensagens',
                    onTap: () => _navigate(context, 'Mensagens', 'messages', auth),
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.person_outline,
                    label: 'Perfil',
                    onTap: () => _navigate(context, 'Perfil', 'profile', auth),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Divider(height: 1),
                  ),
                  if (!auth.isAuthenticated)
                    _menuItem(
                      context: context,
                      icon: Icons.login,
                      label: 'Fazer Login',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                        showAuthModal(context);
                      },
                    ),
                  if (auth.isAuthenticated)
                    _menuItem(
                      context: context,
                      icon: Icons.logout,
                      label: 'Sair',
                      color: AppColors.error,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await context.read<AuthProvider>().logout();
                      },
                    ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Local Viva',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, size: 22, color: color ?? AppColors.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }

  void _navigate(BuildContext context, String title, String route, AuthProvider auth) {
    final requiresAuth = ['create_ad', 'my_ads', 'profile', 'messages', 'favorites'].contains(route);
    Navigator.of(context).pop();
    if (requiresAuth && !auth.isAuthenticated) {
      showAuthModal(context, featureName: title);
      return;
    }
    Navigator.of(context).pushNamed('/$route');
  }
}
