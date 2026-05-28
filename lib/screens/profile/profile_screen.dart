import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
        ),
        elevation: 0,
        title: const Text('Meu Perfil'),
        foregroundColor: Colors.white,
      ),
      body: auth.user == null
          ? const Center(
              child: Text('Usuário não encontrado'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildUserDataTab(auth.user!),
            ),
    );
  }

  Widget _buildUserDataTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // User Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações Pessoais',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nome', user.name),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    _buildInfoRow('Telefone', user.phone!),
                  if (user.emailVerified)
                    _buildInfoRow(
                      'Email Verificado',
                      'Sim',
                      valueColor: AppColors.success,
                    ),
                  if (user.cpf != null && user.cpf!.isNotEmpty)
                    _buildInfoRow('CPF', user.cpf!),
                  if (user.cep != null && user.cep!.isNotEmpty)
                    _buildInfoRow('CEP', user.cep!),
                  if (user.street != null && user.street!.isNotEmpty)
                    _buildInfoRow('Endereço', user.street!),
                  if (user.city != null && user.city!.isNotEmpty)
                    _buildInfoRow('Cidade', '${user.city}${user.stateUf != null ? ' - ${user.stateUf}' : ''}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ações',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: const Text('Editar Perfil'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _redirectToWebsite('perfil');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock, color: AppColors.primary),
                    title: const Text('Alterar Senha'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _redirectToWebsite('senha');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: AppColors.primary),
                    title: const Text('Política de Privacidade'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _redirectToWebsite('privacidade');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Danger Zone
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zona de Perigo',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.delete, color: AppColors.error),
                    title: const Text('Excluir Conta'),
                    subtitle: const Text('Esta ação não pode ser desfeita'),
                    onTap: () {
                      _redirectToWebsite('excluir');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Tem certeza que deseja excluir sua conta? Todos os seus anúncios serão removidos e esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Em breve...')),
                );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _redirectToWebsite(String action) async {
    String url = 'https://localviva.com.br/entrar';
    
    // All actions now redirect to login page
    switch (action) {
      case 'perfil':
      case 'senha':
      case 'excluir':
      case 'notificacoes':
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
          SnackBar(
            content: Text('Visite: $url'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
