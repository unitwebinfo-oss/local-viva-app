import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../utils/string_extension.dart';

class AdCard extends StatelessWidget {
  final AdModel ad;
  final bool showFavorite;
  final VoidCallback? onEdit;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  const AdCard({
    super.key,
    required this.ad,
    this.showFavorite = true,
    this.onEdit,
    required this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ad.primaryImageUrl ??
        (ad.images.isNotEmpty ? ad.images.first : null);
    final bool isBoosted = ad.isBoosted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isBoosted ? 5 : 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 190,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 190,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          height: 190,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                ),
                if (isBoosted && ad.boostLabel.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            ad.boostLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Buttons overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button (only when onEdit is provided)
                      if (onEdit != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: GestureDetector(
                            onTap: onEdit,
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      // Favorite button
                      if (showFavorite)
                        Consumer<FavoritesProvider>(
                          builder: (context, favProvider, child) {
                            final isFavorited = favProvider.isFavorited(ad.id);
                            return Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: GestureDetector(
                                onTap: onFavorite ?? () async {
                                  final auth = Provider.of<AuthProvider>(context, listen: false);
                                  await favProvider.toggleFavorite(ad.id, userId: auth.user?.id);
                                },
                                child: Icon(
                                  isFavorited ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorited ? Colors.red : Colors.white,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ad.title.toLowerCase().capitalizeFirst(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.formattedPrice,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad.location,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
