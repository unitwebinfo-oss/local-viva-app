import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CategoryCard extends StatelessWidget {
  final int id;
  final String name;
  final String? icon;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.id,
    required this.name,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getCategoryIcon(),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Category name
            Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryIcon() {
    if (icon != null && icon!.isNotEmpty) {
      return icon!;
    }
    
    // Default icons based on category name
    final nameLower = name.toLowerCase();
    if (nameLower.contains('imóve') || nameLower.contains('casa') || nameLower.contains('apart')) {
      return '🏠';
    } else if (nameLower.contains('veículo') || nameLower.contains('carro') || nameLower.contains('moto')) {
      return '🚗';
    } else if (nameLower.contains('eletrônico') || nameLower.contains('celular') || nameLower.contains('computador')) {
      return '📱';
    } else if (nameLower.contains('móve') || nameLower.contains('móvel')) {
      return '🛋️';
    } else if (nameLower.contains('roupa') || nameLower.contains('moda')) {
      return '👕';
    } else if (nameLower.contains('esporte') || nameLower.contains('fitness')) {
      return '⚽';
    } else if (nameLower.contains('serviço')) {
      return '🔧';
    } else if (nameLower.contains('emprego') || nameLower.contains('vaga')) {
      return '💼';
    } else if (nameLower.contains('animal') || nameLower.contains('pet')) {
      return '🐾';
    } else if (nameLower.contains('lazer') || nameLower.contains('hobby')) {
      return '🎮';
    }
    
    return '📦';
  }
}
