import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';

class BannerWidget extends StatelessWidget {
  final String? imageUrl;
  final String? linkUrl;
  final String title;
  final VoidCallback? onTap;
  final bool fullWidth;

  const BannerWidget({
    super.key,
    this.imageUrl,
    this.linkUrl,
    required this.title,
    this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: fullWidth 
        ? const EdgeInsets.symmetric(horizontal: 5, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: fullWidth ? BorderRadius.zero : BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => _handleBannerTap(context),
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.contain,
              width: double.infinity,
              placeholder: (context, url) => AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: fullWidth ? BorderRadius.zero : BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: fullWidth ? BorderRadius.zero : BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  double _getBannerHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 768) {
      // Mobile
      return 120;
    } else if (screenWidth < 1200) {
      // Tablet
      return 160;
    } else {
      // Desktop
      return 200;
    }
  }

  Future<void> _handleBannerTap(BuildContext context) async {
    if (linkUrl != null && linkUrl!.isNotEmpty) {
      final Uri url = Uri.parse(linkUrl!);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
