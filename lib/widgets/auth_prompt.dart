import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AuthPrompt extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onTap;

  const AuthPrompt({
    super.key,
    required this.title,
    required this.description,
    this.buttonText = 'Fazer login',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
