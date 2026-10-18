import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../cart/cart_screen.dart';
import 'models/plant.dart';
import 'plant_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.watch<CartProvider>();
    final plants = wishlist.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Wishlist (${plants.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Cart action button
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Shopping Cart',
                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cart.totalCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.botanicalGreen,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        '${cart.totalCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (plants.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              tooltip: 'Clear Wishlist',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Wishlist?'),
                    content: const Text('Are you sure you want to remove all saved plants from your wishlist?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  wishlist.clearWishlist();
                }
              },
            ),
        ],
      ),
      body: plants.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_outline_rounded,
                        size: 54,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Wishlist is Empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save your favorite houseplants, foliage, and succulents to easily order them anytime.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.eco_outlined, size: 18),
                      label: const Text('Explore Plant Catalogue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.botanicalGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: plants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final plant = plants[i];
                return _WishlistPlantCard(
                  plant: plant,
                  onRemove: () => wishlist.removeFromWishlist(plant.id),
                  onAddToCart: () {
                    if (!plant.inStock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This plant is currently out of stock.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    if (cart.isDifferentNursery(plant.nurseryId)) {
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Different Nursery'),
                          content: Text(
                            'Your cart contains plants from "${cart.currentNurseryName ?? "another nursery"}".\n\n'
                            'Orders are fulfilled directly by each nursery. Would you like to clear your cart and start an order from "${plant.nurseryName ?? "this nursery"}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: const Text('Keep Current Cart'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dCtx);
                                cart.addItem(plant, forceClear: true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${plant.name} to cart!'),
                                    backgroundColor: AppColors.botanicalGreen,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.botanicalGreen),
                              child: const Text('Clear & Add'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    cart.addItem(plant);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${plant.name} to cart!'),
                        backgroundColor: AppColors.botanicalGreen,
                        action: SnackBarAction(
                          label: 'View Cart',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _WishlistPlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const _WishlistPlantCard({
    required this.plant,
    required this.onRemove,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Plant thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                      ? Image.network(
                          plant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.botanicalGreenLight,
                            child: const Icon(Icons.local_florist, color: AppColors.botanicalGreen),
                          ),
                        )
                      : Container(
                          color: AppColors.botanicalGreenLight,
                          child: const Icon(Icons.local_florist, color: AppColors.botanicalGreen),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Plant details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.nurseryName ?? 'Verified Nursery Partner',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          plant.formattedPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.botanicalGreenDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: plant.inStock ? AppColors.botanicalGreenLight : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plant.inStock ? '${plant.stock} in stock' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: plant.inStock ? AppColors.botanicalGreenDark : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                    tooltip: 'Remove from Wishlist',
                    onPressed: onRemove,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_shopping_cart,
                      color: plant.inStock ? AppColors.botanicalGreen : AppColors.textMuted,
                      size: 22,
                    ),
                    tooltip: plant.inStock ? 'Add to Cart' : 'Out of Stock',
                    onPressed: plant.inStock ? onAddToCart : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
