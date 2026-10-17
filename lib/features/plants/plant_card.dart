import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import 'models/plant.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onTap;

  const PlantCard({super.key, required this.plant, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Plant image ──────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: plant.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: plant.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                          color: AppColors.botanicalGreenLight,
                          child: const Center(
                            child: Icon(Icons.eco,
                                color: AppColors.botanicalGreen, size: 40),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _PlantPlaceholder(),
                      )
                    : _PlantPlaceholder(),
              ),
            ),
            // ── Info section ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (plant.nurseryName != null && plant.nurseryName!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            plant.nurseryLocationDisplay.isNotEmpty
                                ? '${plant.nurseryName} • ${plant.nurseryLocationDisplay}'
                                : plant.nurseryName!,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${plant.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.botanicalGreenDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      _StockBadge(inStock: plant.inStock, stock: plant.stock),
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

class _PlantPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.botanicalGreenLight,
      child: const Center(
        child: Icon(Icons.local_florist, color: AppColors.botanicalGreen, size: 40),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool inStock;
  final int? stock;
  const _StockBadge({required this.inStock, this.stock});

  @override
  Widget build(BuildContext context) {
    final label = !inStock
        ? 'Out of Stock'
        : (stock != null && stock! > 0 ? '$stock in stock' : 'In Stock');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: inStock ? AppColors.botanicalGreenLight : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: inStock ? AppColors.botanicalGreen : AppColors.error,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
