import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../nurseries/models/nursery.dart';
import 'nursery_profile_screen.dart';
import 'owner_inventory_screen.dart';
import 'our_plant_gallery_screen.dart';
import 'owner_orders_screen.dart';
import 'owner_payment_settings_screen.dart';
import 'owner_reviews_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final owner = context.read<OwnerProvider>();
      owner.fetchOwnerDashboard();
      owner.fetchGallery();
      owner.fetchOwnerOrders();
    });
  }

  Future<void> _refresh() async {
    await context.read<OwnerProvider>().fetchOwnerDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final owner = context.watch<OwnerProvider>();
    final user = auth.currentUser;
    final nursery = owner.nursery;
    final stats = owner.dashboardStats;
    final plantsStats = stats?['plants'] as Map<String, dynamic>?;
    final ordersToday = stats?['ordersToday'] as int? ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nursery Owner Portal'),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to end your session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // ── Profile Greeting Card ───────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlueDark, AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Nursery Owner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'OWNER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (owner.isLoading && nursery == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (owner.errorMessage != null && nursery == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Failed to load dashboard: ${owner.errorMessage}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else ...[
                // ── Nursery Status Card ─────────────────────────────
                if (nursery == null)
                  _buildNoNurseryCard(context)
                else
                  _buildNurseryStatusCard(context, nursery),

                const SizedBox(height: 24),

                // ── KPI Metrics Grid ────────────────────────────────
                Text(
                  'STORE PERFORMANCE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Plants',
                        value: '${plantsStats?['total'] ?? 0}',
                        icon: Icons.local_florist_outlined,
                        color: AppColors.botanicalGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Active Stock',
                        value: '${plantsStats?['active'] ?? 0}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: "Today's Orders",
                        value: '$ordersToday',
                        icon: Icons.shopping_bag_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Management Modules Hub ──────────────────────────
                Text(
                  'MANAGEMENT MODULES',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),

                _buildModuleTile(
                  context,
                  title: 'Nursery Profile & Storefront',
                  subtitle: nursery != null
                      ? 'Edit contact info, address, description, and logo'
                      : 'Set up and register your store profile',
                  icon: Icons.store_rounded,
                  iconColor: AppColors.primaryBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NurseryProfileScreen(initialNursery: nursery),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _buildModuleTile(
                  context,
                  title: 'Plant Inventory Management',
                  subtitle: 'Add new plants, update stock, pricing & care info',
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppColors.botanicalGreen,
                  badge: plantsStats != null ? '${plantsStats['total'] ?? 0} Listed' : null,
                  badgeColor: AppColors.botanicalGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OwnerInventoryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _buildModuleTile(
                  context,
                  title: 'Our Plant Gallery',
                  subtitle: 'Showcase photos of your nursery grounds & real plants',
                  icon: Icons.photo_library_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  badge: '${owner.gallery.length} Photos',
                  badgeColor: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OurPlantGalleryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _buildModuleTile(
                  context,
                  title: 'Customer Orders',
                  subtitle: 'Review incoming purchases, track status & fulfillment',
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  badge: owner.pendingOrdersCount > 0
                      ? '${owner.pendingOrdersCount} Pending'
                      : '${owner.orders.length} Total',
                  badgeColor: owner.pendingOrdersCount > 0
                      ? AppColors.warning
                      : AppColors.textMuted,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OwnerOrdersScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _buildModuleTile(
                  context,
                  title: 'Payment & UPI Settings',
                  subtitle: nursery != null && nursery.isUpiEnabled
                      ? 'UPI Active (${nursery.upiId ?? "Configured"}) • Direct payment'
                      : 'Configure UPI QR image, UPI ID, pickup, and cash settings',
                  icon: Icons.qr_code_2_rounded,
                  iconColor: const Color(0xFF0D9488),
                  badge: nursery != null && nursery.isUpiEnabled ? 'UPI Enabled' : 'Configure',
                  badgeColor: nursery != null && nursery.isUpiEnabled
                      ? AppColors.botanicalGreen
                      : const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OwnerPaymentSettingsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _buildModuleTile(
                  context,
                  title: 'Customer Reviews & Feedback',
                  subtitle: 'View ratings and verified buyer reviews for your plants',
                  icon: Icons.star_outline_rounded,
                  iconColor: const Color(0xFFEC4899),
                  onTap: () {
                    if (nursery != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerReviewsScreen(
                            nurseryId: nursery.id,
                            nurseryName: nursery.name,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please register your nursery profile first to view customer feedback.'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoNurseryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No Nursery Profile Linked',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Your owner account is ready. Register your nursery name, address, and contact details to submit for verification.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: const Text('Register Nursery Now'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NurseryProfileScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNurseryStatusCard(BuildContext context, Nursery nursery) {
    final isVerified = nursery.isVerified;
    final isActive = nursery.isActive;
    final logo = nursery.logoUrl ?? nursery.imageUrl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nursery Logo Thumbnail ─────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppColors.botanicalGreenLight,
                  child: (logo != null && logo.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: logo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.botanicalGreen,
                            size: 26,
                          ),
                        )
                      : const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.botanicalGreen,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nursery.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nursery.locationDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppColors.botanicalGreenLight
                      : AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified
                          ? Icons.verified_rounded
                          : Icons.pending_outlined,
                      size: 13,
                      color: isVerified ? AppColors.botanicalGreen : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified
                          ? 'VERIFIED'
                          : (isActive ? 'PENDING' : 'INACTIVE'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isVerified
                            ? AppColors.botanicalGreenDark
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nursery.phone ?? 'No phone provided',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primaryBlue,
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Profile'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NurseryProfileScreen(initialNursery: nursery),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? AppColors.primaryBlue).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: badgeColor ?? AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
