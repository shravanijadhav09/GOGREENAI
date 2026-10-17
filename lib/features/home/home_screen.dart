import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/constants/app_colors.dart';
import '../cart/cart_screen.dart';
import '../orders/customer_orders_screen.dart';
import '../plants/plant_card.dart';
import '../plants/plant_detail_screen.dart';
import '../nurseries/nursery_detail_screen.dart';
import '../nurseries/models/nursery.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProv = context.read<AppProvider>();
      if (appProv.plantsState == LoadState.idle) appProv.fetchPlants();
      if (appProv.nurseriesState == LoadState.idle) appProv.fetchNurseries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.botanicalGreen,
          onRefresh: () async {
            final app = context.read<AppProvider>();
            await Future.wait([app.fetchPlants(), app.fetchNurseries()]);
          },
          child: CustomScrollView(
            slivers: [
              // ── Top Bar ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.botanicalGreen,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.botanicalGreen.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.eco, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GoGreen-AI',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            user != null ? 'Hi, ${user.fullName.split(' ').first} 👋' : 'Welcome to GoGreen',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // ── My Orders Action ──────────────────────────
                      IconButton(
                        tooltip: 'My Orders',
                        icon: const Icon(Icons.receipt_long_outlined, color: AppColors.textPrimary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()),
                          );
                        },
                      ),
                      // ── Cart Action with Badge ─────────────────────
                      Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          final count = cart.totalCount;
                          return Stack(
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
                      // ── Profile Menu ──────────────────────────────
                      PopupMenuButton<String>(
                        icon: CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.botanicalGreenLight,
                          child: Text(
                            user != null && user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppColors.botanicalGreenDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        offset: const Offset(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: (val) {
                          if (val == 'orders') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()),
                            );
                          } else if (val == 'logout') {
                            auth.logout();
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Customer',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'orders',
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long, size: 18, color: AppColors.textPrimary),
                                SizedBox(width: 10),
                                Text('My Orders', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                                SizedBox(width: 10),
                                Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search & Filter Bar ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => context.read<AppProvider>().setSearchQuery(v),
                          decoration: InputDecoration(
                            hintText: 'Search plants by name, variety…',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: AppColors.botanicalGreen, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<AppProvider>().setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Quick Category Chips ─────────────────────
                      Consumer<AppProvider>(
                        builder: (ctx, appProv, _) {
                          final selectedCat = appProv.selectedCategory;
                          final isMedicinal = appProv.onlyMedicinal;
                          final placement = appProv.selectedPlacement;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All Plants',
                                  icon: Icons.all_inclusive,
                                  isSelected: !appProv.hasActiveFilters,
                                  onTap: () => appProv.resetFilters(),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Indoor',
                                  icon: Icons.home_outlined,
                                  isSelected: placement == 'Indoor',
                                  onTap: () => appProv.setSelectedPlacement(
                                    placement == 'Indoor' ? null : 'Indoor',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Outdoor',
                                  icon: Icons.wb_sunny_outlined,
                                  isSelected: placement == 'Outdoor',
                                  onTap: () => appProv.setSelectedPlacement(
                                    placement == 'Outdoor' ? null : 'Outdoor',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Medicinal 🌿',
                                  icon: Icons.healing_outlined,
                                  isSelected: isMedicinal,
                                  onTap: () => appProv.setOnlyMedicinal(!isMedicinal),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Flowering',
                                  icon: Icons.local_florist_outlined,
                                  isSelected: selectedCat == 'Flowering',
                                  onTap: () => appProv.setSelectedCategory(
                                    selectedCat == 'Flowering' ? null : 'Flowering',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Succulents',
                                  icon: Icons.yard_outlined,
                                  isSelected: selectedCat == 'Succulent',
                                  onTap: () => appProv.setSelectedCategory(
                                    selectedCat == 'Succulent' ? null : 'Succulent',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Nearby Nurseries Section ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.botanicalGreen, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Nearby Nurseries',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Consumer<LocationProvider>(
                            builder: (ctx, loc, _) {
                              if (loc.isLoading) {
                                return const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.botanicalGreen),
                                );
                              }
                              return TextButton.icon(
                                onPressed: () => loc.requestUserLocation(),
                                icon: Icon(
                                  loc.hasLocation ? Icons.my_location : Icons.near_me_outlined,
                                  size: 14,
                                  color: AppColors.botanicalGreen,
                                ),
                                label: Text(
                                  loc.hasLocation ? 'GPS Active' : 'Locate Me',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.botanicalGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _NearbyNurseriesHorizontalList(),
                    ],
                  ),
                ),
              ),

              // ── AI Banner ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _AiBanner(),
                ),
              ),

              // ── Featured Plants Header ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Plants',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Consumer<AppProvider>(
                        builder: (ctx, prov, _) {
                          final count = prov.filteredPlants.length;
                          return Text(
                            '$count available',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Plant Grid with Real Data ─────────────────────────
              Consumer<AppProvider>(
                builder: (ctx, prov, _) {
                  if (prov.plantsState == LoadState.loading) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.botanicalGreen),
                      ),
                    );
                  }
                  if (prov.plantsState == LoadState.error) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textMuted),
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
                        ),
                      ),
                    );
                  }
                  final plants = prov.filteredPlants;
                  if (plants.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.filter_vintage_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No plants match your selected filters.',
                                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => prov.resetFilters(),
                                child: const Text('Reset All Filters', style: TextStyle(color: AppColors.botanicalGreen)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (c, i) => PlantCard(
                          plant: plants[i],
                          onTap: () => Navigator.push(
                            c,
                            MaterialPageRoute(
                              builder: (_) => PlantDetailScreen(plant: plants[i]),
                            ),
                          ),
                        ),
                        childCount: plants.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter Chip Widget ──────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.botanicalGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.botanicalGreen : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.botanicalGreen.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nearby Nurseries Horizontal List ────────────────────────────────
class _NearbyNurseriesHorizontalList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProv = context.watch<AppProvider>();
    final locProv = context.watch<LocationProvider>();

    if (appProv.nurseriesState == LoadState.loading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.botanicalGreen),
        ),
      );
    }

    final nurseries = List<Nursery>.from(appProv.nurseries);
    if (nurseries.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const Text(
          'No partner nurseries registered yet.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    // Sort by real distance if user coordinates are known
    if (locProv.hasLocation) {
      nurseries.sort((a, b) {
        final distA = a.distanceFrom(locProv.latitude, locProv.longitude) ?? 999999;
        final distB = b.distanceFrom(locProv.latitude, locProv.longitude) ?? 999999;
        return distA.compareTo(distB);
      });
    }

    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: nurseries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final n = nurseries[i];
          final distStr = locProv.hasLocation ? n.distanceDisplayFrom(locProv.latitude, locProv.longitude) : null;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => NurseryDetailScreen(nursery: n)),
              );
            },
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.botanicalGreenLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: n.logoUrl != null && n.logoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(n.logoUrl!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.park, color: AppColors.botanicalGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (n.isVerified)
                                  const Icon(Icons.verified, size: 14, color: AppColors.botanicalGreen),
                              ],
                            ),
                            Text(
                              n.city != null && n.city!.isNotEmpty ? n.city! : 'Verified Nursery',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (distStr != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk, size: 11, color: AppColors.primaryBlue),
                              const SizedBox(width: 2),
                              Text(
                                distStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (n.plantCount != null)
                        Text(
                          '${n.plantCount} plants',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.botanicalGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── AI Identifier Banner ────────────────────────────────────────────
class _AiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.botanicalGreenDark, AppColors.botanicalGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.botanicalGreenDark.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Plant Doctor & Guide 🌿',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get instant care tips, disease diagnosis, and light recommendations.',
                  style: TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
