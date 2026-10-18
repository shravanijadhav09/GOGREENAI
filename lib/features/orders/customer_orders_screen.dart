import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../owner/models/nursery_order.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  List<NurseryOrder> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetchMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.get(ApiConstants.customerOrdersEndpoint);
      final list = (res['data'] as List<dynamic>?) ?? [];
      final parsed = list
          .map((json) => NurseryOrder.fromJson(json as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _orders = parsed;
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

  List<NurseryOrder> _filterOrders(int tabIndex) {
    switch (tabIndex) {
      case 1: // Active
        return _orders.where((o) {
          final s = o.status;
          return s == OrderStatusEnum.pendingConfirmation ||
              s == OrderStatusEnum.accepted ||
              s == OrderStatusEnum.preparing ||
              s == OrderStatusEnum.readyForPickup ||
              s == OrderStatusEnum.outForDelivery;
        }).toList();
      case 2: // Completed
        return _orders
            .where((o) => o.status == OrderStatusEnum.completed)
            .toList();
      case 3: // Cancelled / Rejected
        return _orders.where((o) {
          final s = o.status;
          return s == OrderStatusEnum.cancelled ||
              s == OrderStatusEnum.rejected;
        }).toList();
      default: // All
        return _orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Plant Orders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMyOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: AppColors.botanicalGreen,
          labelColor: AppColors.botanicalGreen,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.botanicalGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Could not load your orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchMyOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.botanicalGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filterOrders(_tabController.index);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.botanicalGreenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: AppColors.botanicalGreen,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No orders found',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              const Text(
                'When you place orders for plants, they will appear here for easy tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.botanicalGreen,
      onRefresh: _fetchMyOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (ctx, idx) => _CustomerOrderCard(
          order: filtered[idx],
          onTap: () => _showOrderDetailSheet(filtered[idx]),
        ),
      ),
    );
  }

  void _showOrderDetailSheet(NurseryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CustomerOrderDetailView(order: order),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  final NurseryOrder order;
  final VoidCallback onTap;

  const _CustomerOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt ?? DateTime.now());
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header: ID + Fulfillment Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.botanicalGreenLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$shortId',
                        style: const TextStyle(
                          color: AppColors.botanicalGreenDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                _buildFulfillmentBadge(),
              ],
            ),
            const SizedBox(height: 12),

            // Plant Thumbnails & Item Names
            Row(
              children: [
                _buildItemThumbnails(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _itemsSummaryText(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.items.length == 1
                            ? '1 plant item'
                            : '${order.items.length} different plant varieties',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.botanicalGreenDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),

            // Dual Badges: Fulfillment Status + Payment Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(),
                _buildPaymentStatusBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemThumbnails() {
    if (order.items.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.botanicalGreenLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.local_florist, color: AppColors.botanicalGreen),
      );
    }

    final firstItem = order.items.first;
    final imgUrl = firstItem.plantImageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        color: AppColors.botanicalGreenLight,
        child: imgUrl != null && imgUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.local_florist,
                    color: AppColors.botanicalGreen),
              )
            : const Icon(Icons.local_florist, color: AppColors.botanicalGreen),
      ),
    );
  }

  String _itemsSummaryText() {
    if (order.items.isEmpty) return 'Plant Order';
    final first = order.items.first.plantName;
    if (order.items.length == 1) {
      return '$first (x${order.items.first.quantity})';
    }
    return '$first + ${order.items.length - 1} more';
  }

  Widget _buildFulfillmentBadge() {
    final isPickup = order.fulfillmentType == FulfillmentTypeEnum.pickup;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPickup ? Icons.storefront_outlined : Icons.local_shipping_outlined,
            size: 13,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isPickup ? 'Pickup' : 'Delivery',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bg;
    Color fg;
    String label = order.statusDisplay;

    switch (order.status) {
      case OrderStatusEnum.pendingConfirmation:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case OrderStatusEnum.accepted:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case OrderStatusEnum.preparing:
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        break;
      case OrderStatusEnum.readyForPickup:
      case OrderStatusEnum.outForDelivery:
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        break;
      case OrderStatusEnum.completed:
        bg = AppColors.botanicalGreenLight;
        fg = AppColors.botanicalGreenDark;
        break;
      case OrderStatusEnum.rejected:
      case OrderStatusEnum.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge() {
    Color bg;
    Color fg;
    String label = order.paymentStatusDisplay;

    switch (order.paymentStatus) {
      case PaymentStatusEnum.paid:
        bg = AppColors.botanicalGreenLight;
        fg = AppColors.botanicalGreenDark;
        break;
      case PaymentStatusEnum.submitted:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case PaymentStatusEnum.failed:
      case PaymentStatusEnum.refunded:
        bg = const Color(0xFFFEE2E2);
        fg = AppColors.error;
        break;
      case PaymentStatusEnum.pending:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Pay: $label',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _CustomerOrderDetailView extends StatelessWidget {
  final NurseryOrder order;

  const _CustomerOrderDetailView({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt ?? DateTime.now());
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ListView(
          controller: scrollController,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$shortId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Order Status & Stepper Tracker
            _buildFulfillmentTrackerCard(),
            const SizedBox(height: 20),

            // 2. Plant Items Itemized Card
            const Text(
              'Ordered Items',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < order.items.length; i++) ...[
                    _buildItemRow(order.items[i]),
                    if (i < order.items.length - 1)
                      const Divider(height: 1, color: AppColors.border),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Payment Status & Method Card
            const Text(
              'Payment Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            _buildPaymentDetailCard(context),
            const SizedBox(height: 20),

            // 4. Fulfillment & Contact Info
            const Text(
              'Fulfillment Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            _buildContactInfoCard(),
            const SizedBox(height: 24),

            // Order Total Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.botanicalGreenLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.botanicalGreenDark,
                    ),
                  ),
                  Text(
                    '₹${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.botanicalGreenDark,
                    ),
                  ),
                ],
              ),
            ),

            if (order.status == OrderStatusEnum.completed) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showFeedbackDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.star_rounded),
                label: const Text(
                  'Rate & Review Nursery for this Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    int rating = 5;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Rate this Order',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select rating for this order:',
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
                    labelText: 'Written Review (Optional)',
                    hintText: 'How was the plant quality and service?',
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
                        await ApiClient().post(ApiConstants.feedbacksEndpoint, {
                          'nurseryId': order.nurseryId,
                          'orderId': order.id,
                          'rating': rating,
                          if (commentCtrl.text.trim().isNotEmpty)
                            'comment': commentCtrl.text.trim(),
                        });

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you! Your feedback for this order has been submitted.'),
                              backgroundColor: AppColors.botanicalGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
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

  Widget _buildFulfillmentTrackerCard() {
    final status = order.status;
    final isCancelled = status == OrderStatusEnum.cancelled;
    final isRejected = status == OrderStatusEnum.rejected;

    if (isCancelled || isRejected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.error, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRejected ? 'Order Rejected by Nursery' : 'Order Cancelled',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRejected
                        ? 'The nursery was unable to accept this order (e.g. stock limitation). Reserved items have been released.'
                        : 'This order was cancelled. No charges apply.',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Step indicators
    int activeStep = 0;
    switch (status) {
      case OrderStatusEnum.pendingConfirmation:
        activeStep = 0;
        break;
      case OrderStatusEnum.accepted:
        activeStep = 1;
        break;
      case OrderStatusEnum.preparing:
        activeStep = 2;
        break;
      case OrderStatusEnum.readyForPickup:
      case OrderStatusEnum.outForDelivery:
        activeStep = 3;
        break;
      case OrderStatusEnum.completed:
        activeStep = 4;
        break;
      default:
        activeStep = 0;
    }

    final isPickup = order.fulfillmentType == FulfillmentTypeEnum.pickup;
    final stepTitles = [
      'Placed',
      'Accepted',
      'Preparing',
      isPickup ? 'Ready for Pickup' : 'Out for Delivery',
      'Completed',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.timeline, color: AppColors.botanicalGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Status: ${order.statusDisplay}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.botanicalGreenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal step indicators
          Row(
            children: List.generate(stepTitles.length, (i) {
              final isDone = i <= activeStep;
              final isCurrent = i == activeStep;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.botanicalGreen
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: AppColors.botanicalGreenLight, width: 3)
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stepTitles[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? AppColors.botanicalGreenDark
                            : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: AppColors.botanicalGreenLight,
              child: item.plantImageUrl != null && item.plantImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.plantImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                          Icons.local_florist,
                          color: AppColors.botanicalGreen),
                    )
                  : const Icon(Icons.local_florist,
                      color: AppColors.botanicalGreen),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.plantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price.toStringAsFixed(0)} × ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(item.price * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Method: ${order.paymentMethodDisplay}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.paymentStatus == PaymentStatusEnum.paid
                      ? AppColors.botanicalGreenLight
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.paymentStatusDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: order.paymentStatus == PaymentStatusEnum.paid
                        ? AppColors.botanicalGreenDark
                        : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (order.paymentRef != null && order.paymentRef!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Reference/UTR: ${order.paymentRef}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (order.paymentProofUrl != null && order.paymentProofUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _viewProofDialog(context, order.paymentProofUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: CachedNetworkImage(
                        imageUrl: order.paymentProofUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Screenshot Submitted',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.paymentStatus == PaymentStatusEnum.paid
                            ? 'Verified & confirmed by nursery owner'
                            : 'Pending owner verification',
                        style: TextStyle(
                          fontSize: 11,
                          color: order.paymentStatus == PaymentStatusEnum.paid
                              ? AppColors.botanicalGreenDark
                              : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(
                order.fulfillmentType == FulfillmentTypeEnum.pickup
                    ? Icons.storefront
                    : Icons.local_shipping,
                size: 16,
                color: AppColors.botanicalGreen,
              ),
              const SizedBox(width: 8),
              Text(
                order.fulfillmentType == FulfillmentTypeEnum.pickup
                    ? 'Pickup at Nursery'
                    : 'Home Delivery',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          if (order.customerName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Recipient: ${order.customerName!}',
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ],
          if (order.customerPhone != null) ...[
            const SizedBox(height: 4),
            Text(
              'Phone: ${order.customerPhone!}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Address: ${order.deliveryAddress!}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${order.notes!}',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _viewProofDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Proof'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
