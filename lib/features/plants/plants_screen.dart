import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/constants/app_colors.dart';
import '../cart/cart_screen.dart';
import 'plant_card.dart';
import 'plant_detail_screen.dart';

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<AppProvider>();
      if (prov.plantsState == LoadState.idle) prov.fetchPlants();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    final prov = context.read<AppProvider>();
    double tempMaxPrice = prov.maxPrice ?? 2000;
    String? tempCategory = prov.selectedCategory;
    String? tempPlacement = prov.selectedPlacement;
    bool tempInStock = prov.onlyInStock;
    bool tempMedicinal = prov.onlyMedicinal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Plants',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempMaxPrice = 2000;
                              tempCategory = null;
                              tempPlacement = null;
                              tempInStock = false;
                              tempMedicinal = false;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Placement
                    const Text('Environment / Placement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Indoor', 'Outdoor'].map((place) {
                        final isSel = (place == 'All' && tempPlacement == null) || tempPlacement == place;
                        return ChoiceChip(
                          label: Text(place),
                          selected: isSel,
                          selectedColor: AppColors.botanicalGreenLight,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.botanicalGreenDark : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              tempPlacement = (place == 'All' || !selected) ? null : place;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    const Text('Plant Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        'Flowering',
                        'Foliage',
                        'Succulent',
                        'Bonsai',
                        'Herbs',
                        'Fruit',
                        'Ornamental',
                      ].map((cat) {
                        final isSel = tempCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: AppColors.botanicalGreenLight,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.botanicalGreenDark : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              tempCategory = selected ? cat : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Max Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Maximum Price', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('₹${tempMaxPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.botanicalGreen)),
                      ],
                    ),
                    Slider(
                      value: tempMaxPrice,
                      min: 50,
                      max: 5000,
                      divisions: 99,
                      activeColor: AppColors.botanicalGreen,
                      onChanged: (v) {
                        setModalState(() => tempMaxPrice = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Toggles
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('In-Stock Plants Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      activeThumbColor: AppColors.botanicalGreen,
                      value: tempInStock,
                      onChanged: (v) => setModalState(() => tempInStock = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Medicinal / Ayurvedic Use Only 🌿', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      activeThumbColor: AppColors.botanicalGreen,
                      value: tempMedicinal,
                      onChanged: (v) => setModalState(() => tempMedicinal = v),
                    ),
                    const SizedBox(height: 20),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.botanicalGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          prov.setSelectedPlacement(tempPlacement);
                          prov.setSelectedCategory(tempCategory);
                          prov.setMaxPrice(tempMaxPrice < 5000 ? tempMaxPrice : null);
                          prov.setOnlyInStock(tempInStock);
                          prov.setOnlyMedicinal(tempMedicinal);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prov = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plant Catalogue'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Filter button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.textPrimary),
                tooltip: 'Filter Plants',
                onPressed: () => _showFilterModal(context),
              ),
              if (prov.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.botanicalGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Cart button with badge
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final count = cart.totalCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
                    tooltip: 'Cart',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.botanicalGreen,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
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
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => context.read<AppProvider>().setSearchQuery(v),
              decoration: InputDecoration(
                hintText: 'Search plants by name…',
                filled: true,
                fillColor: AppColors.background,
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<AppProvider>().setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Active Filters Bar ─────────────────────────────────
          if (prov.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.botanicalGreenLight.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: AppColors.botanicalGreenDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Filters active • ${prov.filteredPlants.length} plants',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.botanicalGreenDark),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _searchCtrl.clear();
                      prov.resetFilters();
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // ── Grid / States ───────────────────────────────────────
          Expanded(
            child: Consumer<AppProvider>(
              builder: (ctx, prov, _) {
                if (prov.plantsState == LoadState.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.botanicalGreen),
                  );
                }
                if (prov.plantsState == LoadState.error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Could not load plant catalogue', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: prov.fetchPlants,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.botanicalGreen),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final plants = prov.filteredPlants;
                if (plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No plants match your filters.',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            prov.resetFilters();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.botanicalGreen),
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.botanicalGreen,
                  onRefresh: () => prov.fetchPlants(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: plants.length,
                    itemBuilder: (ctx, i) => PlantCard(
                      plant: plants[i],
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => PlantDetailScreen(plant: plants[i]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
