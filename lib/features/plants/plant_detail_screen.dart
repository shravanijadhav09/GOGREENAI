import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/gemini_service.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../nurseries/nursery_detail_screen.dart';
import '../orders/checkout_screen.dart';
import '../reminders/plant_care_reminders_screen.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/language_provider.dart';
import 'wishlist_screen.dart';
import 'models/plant.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final GeminiService _gemini = GeminiService();
  PlantCareAdviceResult? _aiAdviceResult;
  String? _adviceError;
  bool _loadingAdvice = false;
  int _quantity = 1;

  void _getAiCareAdvice() async {
    final langCode = context.read<LanguageProvider>().languageCode;
    setState(() {
      _loadingAdvice = true;
      _aiAdviceResult = null;
      _adviceError = null;
    });

    try {
      final advice = await _gemini.getPlantCareAdvice(
        widget.plant.name,
        language: langCode,
      );
      if (mounted) {
        setState(() {
          _aiAdviceResult = advice;
          _loadingAdvice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adviceError = 'Could not retrieve AI care advice. Check backend server and Gemini key.';
          _loadingAdvice = false;
        });
      }
    }
  }

  Future<void> _toggleWishlist() async {
    final wishlist = context.read<WishlistProvider>();
    final added = await wishlist.toggleWishlist(widget.plant);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '❤️ Added ${widget.plant.name} to your Wishlist!'
                : 'Removed ${widget.plant.name} from Wishlist.',
          ),
          backgroundColor: AppColors.botanicalGreen,
          duration: const Duration(seconds: 2),
          action: added
              ? SnackBarAction(
                  label: 'View Wishlist',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    final plant = widget.plant;

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
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Different Nursery'),
          content: Text(
            'Your cart contains plants from "${cart.currentNurseryName ?? "another nursery"}".\n\n'
            'Each order is fulfilled and paid directly to a single nursery. Would you like to clear your cart and start a new order from "${plant.nurseryName ?? "this nursery"}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Current Cart'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                cart.addItem(plant, quantity: _quantity, forceClear: true);
                _showAddedToCartSnackBar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.botanicalGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear & Add'),
            ),
          ],
        ),
      );
      return;
    }

    cart.addItem(plant, quantity: _quantity);
    _showAddedToCartSnackBar();
  }

  void _showAddedToCartSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity × ${widget.plant.name} to cart!'),
        backgroundColor: AppColors.botanicalGreen,
        duration: const Duration(seconds: 3),
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
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar with Hero Image ─────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.botanicalGreen,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: plant.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: plant.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.botanicalGreenLight,
                        child: const Center(
                          child: Icon(Icons.eco,
                              color: AppColors.botanicalGreen, size: 64),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.botanicalGreenLight,
                        child: const Center(
                          child: Icon(Icons.local_florist,
                              color: AppColors.botanicalGreen, size: 64),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.botanicalGreenLight,
                      child: const Center(
                        child: Icon(Icons.local_florist,
                            color: AppColors.botanicalGreen, size: 64),
                      ),
                    ),
            ),
            actions: [
              Consumer<WishlistProvider>(
                builder: (ctx, wishlist, _) {
                  final isFav = wishlist.isWishlisted(plant.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: _toggleWishlist,
                    tooltip: 'Wishlist',
                  );
                },
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    tooltip: 'View Cart',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (cart.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.itemCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),


          // ── Plant Content Details ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (plant.category != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                plant.category!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${plant.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.botanicalGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: plant.inStock
                                  ? AppColors.botanicalGreenLight
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              plant.inStock
                                  ? '${plant.stock} In Stock'
                                  : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: plant.inStock
                                    ? AppColors.botanicalGreen
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Set Care Reminder Button ──────────────────────
                  InkWell(
                    onTap: () {
                      int defaultFreq = 3;
                      final w = widget.plant.watering?.toUpperCase() ?? '';
                      if (w.contains('HIGH') || w.contains('DAILY')) {
                        defaultFreq = 1;
                      } else if (w.contains('LOW') || w.contains('WEEKLY')) {
                        defaultFreq = 7;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlantCareRemindersScreen(
                            initialPlantName: widget.plant.name,
                            initialPlantId: widget.plant.id,
                            initialImageUrl: widget.plant.imageUrl,
                            initialFrequencyDays: defaultFreq,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.botanicalGreenLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.botanicalGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alarm_add_rounded, color: AppColors.botanicalGreen, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set Care & Watering Reminder',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.botanicalGreenDark,
                                  ),
                                ),
                                Text(
                                  'Get scheduled alerts for watering & fertilizing this plant',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.botanicalGreen),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Care Spec Grid ─────────────────────────────────
                  Row(
                    children: [
                      _CareSpecTile(
                        icon: Icons.water_drop_outlined,
                        label: 'Water',
                        value: plant.watering ?? 'Moderate',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _CareSpecTile(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Sunlight',
                        value: plant.sunlight ?? 'Indirect',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      _CareSpecTile(
                        icon: Icons.home_outlined,
                        label: 'Placement',
                        value: plant.placementLabel,
                        color: AppColors.botanicalGreen,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _CareSpecTile(
                        icon: Icons.speed_outlined,
                        label: 'Difficulty',
                        value: plant.careDifficulty ?? 'Easy',
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _CareSpecTile(
                        icon: Icons.pets_outlined,
                        label: 'Pet Safe',
                        value: plant.isPetSafe == true ? 'Yes' : 'No / Caution',
                        color: plant.isPetSafe == true
                            ? AppColors.botanicalGreen
                            : Colors.deepOrange,
                      ),
                    ],
                  ),

                  // ── Nursery Origin Card ────────────────────────────
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NurseryDetailScreen(
                            nurseryId: plant.nurseryId,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: AppColors.botanicalGreenLight,
                              child: plant.nurseryLogoUrl != null &&
                                      plant.nurseryLogoUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: plant.nurseryLogoUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(
                                          Icons.storefront,
                                          color: AppColors.botanicalGreen),
                                    )
                                  : const Icon(Icons.storefront,
                                      color: AppColors.botanicalGreen),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        plant.nurseryName ?? 'Verified Nursery',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.verified,
                                        color: AppColors.botanicalGreen, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plant.nurseryLocationDisplay.isNotEmpty
                                      ? plant.nurseryLocationDisplay
                                      : 'Tap to view nursery & other plants',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),

                  // ── Quantity Stepper ───────────────────────────────
                  if (plant.inStock) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quantity',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${plant.stock} available',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: _quantity < plant.stock
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── About Section ──────────────────────────────────
                  const Text(
                    'About this Plant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plant.description ??
                        'A beautiful, healthy specimen supplied by verified nursery partners. Perfect for enhancing indoor air quality or garden aesthetics.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  if (plant.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: plant.tags.map((t) {
                        return Chip(
                          label: Text('#$t', style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Gemini AI Care Assistant Card ───────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.botanicalGreenLight,
                          Colors.green.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.botanicalGreen
                              .withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.botanicalGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.smart_toy_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gemini AI Botanist Advice',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Instant personalized care guide',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_aiAdviceResult == null && !_loadingAdvice) ...[
                          if (_adviceError != null) ...[
                            Text(
                              _adviceError!,
                              style: const TextStyle(fontSize: 12, color: AppColors.error),
                            ),
                            const SizedBox(height: 8),
                          ],
                          ElevatedButton.icon(
                            onPressed: _getAiCareAdvice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.botanicalGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: Text('Generate Care Advice for ${plant.name}'),
                          ),
                        ],
                        if (_loadingAdvice)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.botanicalGreen,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Gemini AI is analyzing plant care...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_aiAdviceResult != null) ...[
                          Text(
                            _aiAdviceResult!.shortAnswer,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Guidance items
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.water_drop_outlined, size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Watering: ${_aiAdviceResult!.wateringGuidance}',
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.wb_sunny_outlined, size: 18, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Sunlight: ${_aiAdviceResult!.lightRequirements}',
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.yard_outlined, size: 18, color: AppColors.botanicalGreen),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Soil: ${_aiAdviceResult!.soilConditions}',
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_aiAdviceResult!.careSteps.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Actionable Care Steps:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            ..._aiAdviceResult!.careSteps.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${entry.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 12))),
                                  ],
                                ),
                              );
                            }),
                          ],
                          if (_aiAdviceResult!.warnings.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _aiAdviceResult!.warnings.join(' • '),
                                      style: TextStyle(fontSize: 11.5, color: Colors.orange.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _getAiCareAdvice,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Regenerate Advice'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.botanicalGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Consumer<WishlistProvider>(
                  builder: (ctx, wishlist, _) {
                    final isFav = wishlist.isWishlisted(plant.id);
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.redAccent : AppColors.textSecondary,
                      ),
                      onPressed: _toggleWishlist,
                      tooltip: 'Save to Wishlist',
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: plant.inStock ? _addToCart : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: plant.inStock
                          ? AppColors.botanicalGreen
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.add_shopping_cart_rounded,
                    size: 18,
                    color: plant.inStock
                        ? AppColors.botanicalGreen
                        : AppColors.textMuted,
                  ),
                  label: Text(
                    'Add to Cart',
                    style: TextStyle(
                      color: plant.inStock
                          ? AppColors.botanicalGreen
                          : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: plant.inStock
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(plant: plant),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.botanicalGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text(
                    'Buy Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareSpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CareSpecTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
