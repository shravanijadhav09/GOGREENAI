import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../cart/cart_screen.dart';
import '../owner/models/gallery_image.dart';
import '../plants/models/plant.dart';
import '../plants/plant_card.dart';
import '../plants/plant_detail_screen.dart';
import 'models/feedback_model.dart';
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
  List<GalleryImage> _galleryImages = [];
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selected tab: 0 = Plants, 1 = Gallery, 2 = Reviews
  int _selectedTabIndex = 0;
  String? _selectedGalleryCategory;

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
      // 1. Fetch nursery details
      final nurseryFuture = _api.get('${ApiConstants.nurseriesEndpoint}/$targetId');
      // 2. Fetch plants for this specific nursery
      final plantsFuture = _api.get('${ApiConstants.plantsEndpoint}?nurseryId=$targetId');
      // 3. Fetch nursery gallery
      final galleryFuture = _api.get(ApiConstants.nurseryGalleryEndpoint(targetId));
      // 4. Fetch nursery feedbacks
      final feedbacksFuture = _api.get(ApiConstants.nurseryFeedbacksEndpoint(targetId));

      final results = await Future.wait([nurseryFuture, plantsFuture, galleryFuture, feedbacksFuture]);
      final nurseryData = results[0]['data'] as Map<String, dynamic>?;
      final plantsData = results[1]['data'] as List<dynamic>? ?? [];
      final galleryData = results[2]['data'] as List<dynamic>? ?? [];
      final feedbacksData = results[3]['data'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          if (nurseryData != null) {
            _nursery = Nursery.fromJson(nurseryData);
          }
          _plants = plantsData
              .map((j) => Plant.fromJson(j as Map<String, dynamic>))
              .toList();
          _galleryImages = galleryData
              .map((j) => GalleryImage.fromJson(j as Map<String, dynamic>))
              .toList();
          _feedbacks = feedbacksData
              .map((j) => FeedbackModel.fromJson(j as Map<String, dynamic>))
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

  Future<void> _openWhatsApp(String phone, String nurseryName) async {
    String clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      clean = '91$clean';
    }
    final message = Uri.encodeComponent(
        'Hello! I found your nursery "$nurseryName" on GoGreenAI and would like to ask about plant availability.');
    final url = Uri.parse('https://wa.me/$clean?text=$message');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening WhatsApp: $e')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email, String nurseryName) async {
    final subject = Uri.encodeComponent('Plant Inquiry - $nurseryName');
    final url = Uri.parse('mailto:$email?subject=$subject');
    try {
      final launched = await launchUrl(url);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching email: $e')),
        );
      }
    }
  }

  Future<void> _showWriteReviewDialog() async {
    int rating = 5;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Rate ${_nursery?.name ?? "Nursery"}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select your rating:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      onPressed: () {
                        setDialogState(() => rating = starIndex);
                      },
                      icon: Icon(
                        starIndex <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Written Feedback (Optional)',
                    hintText: 'Share your experience with their plants and service...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.botanicalGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _api.post(ApiConstants.feedbacksEndpoint, {
                          'nurseryId': widget.effectiveNurseryId,
                          'rating': rating,
                          if (commentCtrl.text.trim().isNotEmpty)
                            'comment': commentCtrl.text.trim(),
                        });

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Feedback submitted successfully! Thank you!'),
                            backgroundColor: AppColors.botanicalGreen,
                          ),
                        );
                        _loadData();
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit review: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenImage(GalleryImage image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: image.url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            if ((image.category != null && image.category!.isNotEmpty) ||
                (image.caption != null && image.caption!.isNotEmpty))
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (image.category != null && image.category!.isNotEmpty)
                        Text(
                          image.category!,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (image.caption != null && image.caption!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          image.caption!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
                      color: Colors.black.withOpacity(0.03),
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
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Rating Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 14, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          nursery.averageRating > 0
                                              ? '${nursery.averageRating.toStringAsFixed(1)} (${nursery.totalRatings})'
                                              : 'New (No ratings)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (distanceDisplay != null) ...[
                                    const SizedBox(width: 8),
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

                    // Quick Actions: Directions, Call, WhatsApp, Email
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _openDirections(nursery),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.botanicalGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.directions_rounded, size: 16),
                          label: const Text(
                            'Directions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        if (nursery.phone != null &&
                            nursery.phone!.trim().isNotEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: () => _callNursery(nursery.phone!),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.botanicalGreen),
                              foregroundColor: AppColors.botanicalGreen,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.phone_outlined, size: 16),
                            label: const Text(
                              'Call',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openWhatsApp(nursery.phone!, nursery.name),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF25D366)),
                              foregroundColor: const Color(0xFF1E824C),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                        if (nursery.email != null &&
                            nursery.email!.trim().isNotEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: () =>
                                _sendEmail(nursery.email!, nursery.name),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.blue.shade600),
                              foregroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.email_outlined, size: 16),
                            label: const Text(
                              'Email',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
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

          // ── Real Nursery Gallery Category Cards ──────────────────────
          _buildCategoryCardsSliver(),

          // Segmented Navigation Header (Plants, Gallery, Reviews)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildSegmentButton(0, 'Plants (${_plants.length})', Icons.eco_outlined),
                    _buildSegmentButton(1, 'Gallery (${_galleryImages.length})', Icons.photo_library_outlined),
                    _buildSegmentButton(2, 'Reviews (${_feedbacks.length})', Icons.star_rate_rounded),
                  ],
                ),
              ),
            ),
          ),

          // Tab Body Content
          if (_selectedTabIndex == 0)
            ..._buildPlantsTab()
          else if (_selectedTabIndex == 1)
            ..._buildGalleryTab()
          else
            ..._buildReviewsTab(),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.botanicalGreen : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.botanicalGreenDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesCategory(String? itemCat, String targetCat) {
    if (itemCat == null) return false;
    final a = itemCat.toLowerCase();
    final b = targetCat.toLowerCase();
    if (a == b) return true;
    if (b.contains('indoor') && a.contains('indoor')) return true;
    if (b.contains('outdoor') && a.contains('outdoor')) return true;
    if ((b.contains('medicinal') || b.contains('aushadhi')) &&
        (a.contains('medicinal') || a.contains('aushadhi'))) {
      return true;
    }
    if (b.contains('general') && a.contains('general')) return true;
    return false;
  }

  Widget _buildCategoryCardsSliver() {
    final categories = [
      {
        'title': 'Indoor Plants',
        'category': GalleryCategories.indoor,
        'icon': Icons.home_outlined,
        'fallback': 'https://images.unsplash.com/photo-1545241047-6083a3684587?w=600&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Outdoor Plants',
        'category': GalleryCategories.outdoor,
        'icon': Icons.park_outlined,
        'fallback': 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=600&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Medicinal / Aushadhi',
        'category': GalleryCategories.medicinal,
        'icon': Icons.healing_outlined,
        'fallback': 'https://images.unsplash.com/photo-1512428559087-560fa5ceab42?w=600&auto=format&fit=crop&q=80',
      },
      {
        'title': 'General',
        'category': GalleryCategories.general,
        'icon': Icons.grid_view_outlined,
        'fallback': 'https://images.unsplash.com/photo-1463936575829-25148e1db1b8?w=600&auto=format&fit=crop&q=80',
      },
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.collections_outlined, size: 18, color: AppColors.botanicalGreen),
                const SizedBox(width: 8),
                const Text(
                  'Nursery Gallery & Plant Sections',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_galleryImages.length} Gallery Photos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final catItem = categories[i];
                  final cat = catItem['category'] as String;
                  final title = catItem['title'] as String;
                  final icon = catItem['icon'] as IconData;
                  final fallbackUrl = catItem['fallback'] as String;

                  // Find real uploaded gallery photos for this category
                  final galleryMatch = _galleryImages.where((img) => _matchesCategory(img.category, cat)).toList();
                  // Find plant matching category
                  final plantMatch = _plants.where((p) {
                    if (cat == GalleryCategories.indoor) return p.isIndoor == true;
                    if (cat == GalleryCategories.outdoor) return p.isOutdoor == true;
                    if (cat == GalleryCategories.medicinal) return p.isMedicinal;
                    return (p.isIndoor != true) && (p.isOutdoor != true) && !p.isMedicinal;
                  }).toList();

                  final plantImageUrl = plantMatch.isNotEmpty ? plantMatch.first.imageUrl : null;
                  final String coverUrl = (galleryMatch.isNotEmpty && galleryMatch.first.url.isNotEmpty)
                      ? galleryMatch.first.url
                      : ((plantImageUrl != null && plantImageUrl.isNotEmpty)
                          ? plantImageUrl
                          : fallbackUrl);

                  final isCurrentSelected = _selectedTabIndex == 1 && _selectedGalleryCategory == cat;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                        _selectedGalleryCategory = cat;
                      });
                    },
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrentSelected ? AppColors.botanicalGreen : AppColors.border,
                          width: isCurrentSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey.shade200),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.botanicalGreenLight,
                                child: Icon(icon, color: AppColors.botanicalGreen, size: 36),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.15),
                                    Colors.black.withOpacity(0.85),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: galleryMatch.isNotEmpty ? AppColors.botanicalGreen : Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  galleryMatch.isNotEmpty
                                      ? '${galleryMatch.length} Photos'
                                      : '${plantMatch.length} Plants',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(icon, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    galleryMatch.isNotEmpty
                                        ? 'View Real Gallery'
                                        : 'View Section',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Plants ──────────────────────────────────────────────────────────
  List<Widget> _buildPlantsTab() {
    if (_plants.isEmpty) {
      return [
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
      ];
    }

    return [
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
    ];
  }

  // ── Tab 2: Gallery ─────────────────────────────────────────────────────────
  List<Widget> _buildGalleryTab() {
    final filtered = _selectedGalleryCategory == null
        ? _galleryImages
        : _galleryImages
            .where((img) => img.category == _selectedGalleryCategory)
            .toList();

    return [
      // Category filter bar
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedGalleryCategory == null,
                  onSelected: (_) {
                    setState(() => _selectedGalleryCategory = null);
                  },
                  selectedColor: AppColors.botanicalGreenLight,
                  checkmarkColor: AppColors.botanicalGreen,
                ),
              ),
              ...GalleryCategories.all.map((cat) {
                final isSel = _selectedGalleryCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSel,
                    onSelected: (val) {
                      setState(() {
                        _selectedGalleryCategory = val ? cat : null;
                      });
                    },
                    selectedColor: AppColors.botanicalGreenLight,
                    checkmarkColor: AppColors.botanicalGreen,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      if (filtered.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  _selectedGalleryCategory == null
                      ? 'No gallery photos added yet.'
                      : 'No photos under "$_selectedGalleryCategory".',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final img = filtered[i];
                return GestureDetector(
                  onTap: () => _openFullscreenImage(img),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: img.url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                        if (img.category != null && img.category!.isNotEmpty)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                img.category!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (img.caption != null && img.caption!.isNotEmpty)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.75),
                                  ],
                                ),
                              ),
                              child: Text(
                                img.caption!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
          ),
        ),
    ];
  }

  // ── Tab 3: Reviews & Ratings ───────────────────────────────────────────────
  List<Widget> _buildReviewsTab() {
    final nursery = _nursery;
    final avg = nursery?.averageRating ?? 0.0;
    final total = nursery?.totalRatings ?? _feedbacks.length;

    return [
      // Summary Header Card + Write Review Button
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          avg > 0 ? avg.toStringAsFixed(1) : '—',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                      ],
                    ),
                    Text(
                      '$total verified rating${total == 1 ? "" : "s"}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showWriteReviewDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.botanicalGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text(
                    'Write Review',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Reviews List
      if (_feedbacks.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.reviews_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No reviews yet. Be the first to share your experience!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final fb = _feedbacks[i];
              final dateStr = DateFormat('dd MMM yyyy').format(fb.createdAt);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.botanicalGreenLight,
                                child: Text(
                                  fb.userName != null && fb.userName!.isNotEmpty
                                      ? fb.userName![0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.botanicalGreenDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                fb.userName ?? 'Verified Customer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (starIdx) {
                          return Icon(
                            starIdx < fb.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      if (fb.comment != null && fb.comment!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          fb.comment!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            childCount: _feedbacks.length,
          ),
        ),
    ];
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
