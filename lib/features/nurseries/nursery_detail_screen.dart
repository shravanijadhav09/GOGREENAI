import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../cart/cart_screen.dart';
import '../plants/models/plant.dart';
import '../plants/plant_card.dart';
import '../plants/plant_detail_screen.dart';
import 'models/nursery.dart';

class NurseryDetailScreen extends StatefulWidget {
  final String? nurseryId;
  final Nursery? nursery;

  const NurseryDetailScreen({
    super.key,
    this.nurseryId,
    this.nursery,
  });

  String get effectiveNurseryId => nurseryId ?? nursery?.id ?? '';

  @override
  State<NurseryDetailScreen> createState() => _NurseryDetailScreenState();
}

class _NurseryDetailScreenState extends State<NurseryDetailScreen> {
  final ApiClient _api = ApiClient();
  Nursery? _nursery;
  List<Plant> _plants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nursery = widget.nursery;
    _loadData();
  }

  Future<void> _loadData() async {
    final targetId = widget.effectiveNurseryId;
    if (targetId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No nursery ID specified.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch nursery details if not provided or to ensure full data
      final nurseryFuture = _api.get('${ApiConstants.nurseriesEndpoint}/$targetId');
      // 2. Fetch plants for this specific nursery
      final plantsFuture = _api.get('${ApiConstants.plantsEndpoint}?nurseryId=$targetId');

      final results = await Future.wait([nurseryFuture, plantsFuture]);
      final nurseryData = results[0]['data'] as Map<String, dynamic>?;
      final plantsData = results[1]['data'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          if (nurseryData != null) {
            _nursery = Nursery.fromJson(nurseryData);
          }
          _plants = plantsData
              .map((j) => Plant.fromJson(j as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openDirections(Nursery nursery) async {
    Uri url;
    if (nursery.hasCoordinates) {
      url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${nursery.latitude},${nursery.longitude}');
    } else {
      final query = [nursery.name, nursery.address, nursery.city, nursery.state]
          .where((p) => p != null && p.trim().isNotEmpty)
          .join(', ');
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    }

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open map navigation app.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching maps: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _callNursery(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$clean');
    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not dial $phone: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nursery = _nursery;
    final loc = context.watch<LocationProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          nursery?.name ?? 'Nursery Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          // Cart action with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.botanicalGreen,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
      body: _buildBody(nursery, loc),
    );
  }

  Widget _buildBody(Nursery? nursery, LocationProvider loc) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.botanicalGreen),
      );
    }

    if (_errorMessage != null || nursery == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 54, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Nursery details unavailable',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final distanceDisplay =
        nursery.distanceDisplayFrom(loc.userLatitude, loc.userLongitude);

    return RefreshIndicator(
      color: AppColors.botanicalGreen,
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Nursery Info Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 68,
                            height: 68,
                            color: AppColors.botanicalGreenLight,
                            child: nursery.logoUrl != null &&
                                    nursery.logoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: nursery.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.park_rounded,
                                      color: AppColors.botanicalGreen,
                                      size: 32,
                                    ),
                                  )
                                : const Icon(
                                    Icons.park_rounded,
                                    color: AppColors.botanicalGreen,
                                    size: 32,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      nursery.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (nursery.isVerified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.verified,
                                        color: AppColors.botanicalGreen,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nursery.locationDisplay,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              if (distanceDisplay != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.botanicalGreenLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.near_me,
                                          size: 12,
                                          color: AppColors.botanicalGreenDark),
                                      const SizedBox(width: 4),
                                      Text(
                                        distanceDisplay,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.botanicalGreenDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (nursery.description != null &&
                        nursery.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        nursery.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 14),

                    // Quick Actions: Directions & Call
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openDirections(nursery),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.botanicalGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: const Text(
                              'Get Directions',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        if (nursery.phone != null &&
                            nursery.phone!.trim().isNotEmpty) ...[
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => _callNursery(nursery.phone!),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.botanicalGreen),
                              foregroundColor: AppColors.botanicalGreen,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.phone_outlined, size: 18),
                            label: const Text(
                              'Call',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Accepted Payment Methods Badges
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (nursery.isUpiEnabled)
                          _buildPaymentPill(
                              Icons.qr_code_2, 'Direct UPI QR Accepted'),
                        if (nursery.isPayAtPickupEnabled)
                          _buildPaymentPill(Icons.storefront, 'Pay at Pickup'),
                        if (nursery.isCodEnabled)
                          _buildPaymentPill(
                              Icons.local_atm, 'Cash on Delivery'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Available Plants Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Plants (${_plants.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_plants.isNotEmpty)
                    Text(
                      'Fresh nursery stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Plants Grid or Empty State
          if (_plants.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.nature_people_outlined,
                          size: 54, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No plants currently listed by this nursery.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final p = _plants[i];
                    return PlantCard(
                      plant: p,
                      onTap: () {
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => PlantDetailScreen(plant: p),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _plants.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildPaymentPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.botanicalGreenDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
