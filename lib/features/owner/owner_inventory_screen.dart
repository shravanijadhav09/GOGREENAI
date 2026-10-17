import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/owner_provider.dart';
import '../plants/models/plant.dart';
import 'add_edit_plant_screen.dart';

class OwnerInventoryScreen extends StatefulWidget {
  const OwnerInventoryScreen({super.key});

  @override
  State<OwnerInventoryScreen> createState() => _OwnerInventoryScreenState();
}

class _OwnerInventoryScreenState extends State<OwnerInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<OwnerProvider>().fetchInventory();
  }

  void _showQuickStockDialog(Plant plant) {
    int current = plant.stock;
    final controller = TextEditingController(text: '$current');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock: ${plant.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the new available quantity in your nursery stock:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Available Units',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                Navigator.pop(ctx);
                final success = await context.read<OwnerProvider>().updateStock(plant.id, val);
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock updated to $val units!'),
                      backgroundColor: AppColors.botanicalGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Plant plant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Plant Listing?'),
        content: Text(
          'Are you sure you want to remove "${plant.name}" from your active inventory? This will deactivate the listing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<OwnerProvider>().deletePlant(plant.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plant.name} removed from inventory.'),
            backgroundColor: AppColors.botanicalGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<OwnerProvider>();
    final plants = owner.filteredInventory;
    final nursery = owner.nursery;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plant Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              // ── Search Bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => owner.setInventorySearch(val),
                  decoration: InputDecoration(
                    hintText: 'Search plant by name, category...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              owner.setInventorySearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),

              // ── Filter Pills ───────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All (${owner.inventory.length})',
                      selected: owner.inventoryFilter == 'all',
                      onSelected: () => owner.setInventoryFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'In Stock (${owner.inventory.where((p) => p.inStock && p.isActive).length})',
                      selected: owner.inventoryFilter == 'in_stock',
                      onSelected: () => owner.setInventoryFilter('in_stock'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Out of Stock (${owner.inventory.where((p) => !p.inStock && p.isActive).length})',
                      selected: owner.inventoryFilter == 'out_of_stock',
                      onSelected: () => owner.setInventoryFilter('out_of_stock'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Inactive (${owner.inventory.where((p) => !p.isActive).length})',
                      selected: owner.inventoryFilter == 'inactive',
                      onSelected: () => owner.setInventoryFilter('inactive'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.botanicalGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Plant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () {
          if (nursery == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please register your nursery profile before adding plant listings.'),
                backgroundColor: AppColors.warning,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditPlantScreen()),
          );
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: owner.isInventoryLoading && owner.inventory.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : owner.inventoryError != null && owner.inventory.isEmpty
                  ? _buildErrorView(owner.inventoryError!)
                  : plants.isEmpty
                      ? _buildEmptyView()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                          itemCount: plants.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            return _buildPlantInventoryCard(plants[index]);
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: AppColors.botanicalGreen,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.botanicalGreen : AppColors.border,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPlantInventoryCard(Plant plant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Plant Image Thumbnail ────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 76,
                height: 76,
                color: AppColors.botanicalGreenLight,
                child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: plant.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.local_florist_rounded,
                          color: AppColors.botanicalGreen,
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.local_florist_rounded,
                        color: AppColors.botanicalGreen,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Plant Details ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plant.name,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Active/Inactive badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: plant.isActive
                              ? AppColors.botanicalGreenLight
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          plant.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: plant.isActive
                                ? AppColors.botanicalGreenDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plant.category ?? 'General Plant',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Price & Stock ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${plant.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.botanicalGreenDark,
                        ),
                      ),
                      // Stock Counter Pill
                      GestureDetector(
                        onTap: () => _showQuickStockDialog(plant),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: plant.inStock
                                ? AppColors.primaryBlueLight
                                : AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: plant.inStock
                                  ? AppColors.primaryBlue.withOpacity(0.3)
                                  : AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                plant.inStock
                                    ? Icons.inventory_2_outlined
                                    : Icons.warning_amber_rounded,
                                size: 13,
                                color: plant.inStock ? AppColors.primaryBlue : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                plant.inStock ? '${plant.stock} in stock' : 'Out of stock',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: plant.inStock ? AppColors.primaryBlue : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Context Actions Menu ─────────────────────────────
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
              onSelected: (action) {
                if (action == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditPlantScreen(existingPlant: plant),
                    ),
                  );
                } else if (action == 'toggle_status') {
                  context.read<OwnerProvider>().togglePlantStatus(plant.id, !plant.isActive);
                } else if (action == 'delete') {
                  _confirmDelete(plant);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Edit Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        plant.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(plant.isActive ? 'Hide Listing' : 'Make Active'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                      SizedBox(width: 10),
                      Text('Delete Plant', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.botanicalGreenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_florist_outlined,
                color: AppColors.botanicalGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Plant Listings Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No plants matched your search query.'
                  : 'Start listing plants to showcase and sell to customers across GoGreen.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Plant'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditPlantScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Inventory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
