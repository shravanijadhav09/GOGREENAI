import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/owner_provider.dart';
import 'models/nursery_order.dart';

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchOwnerOrders(refresh: true);
    });
  }

  Future<void> _changeStatus(
    NurseryOrder order,
    OrderStatusEnum newStatus,
    String actionName, {
    String? customNote,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName Order?'),
        content: Text(
          'Are you sure you want to change order #${order.shortId} status to "${newStatus.label}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus.color,
              foregroundColor: Colors.white,
            ),
            child: Text(actionName),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<OwnerProvider>().updateOrderStatus(
            order.id,
            newStatus,
            note: customNote,
          );
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.shortId} marked as ${newStatus.label}!'),
            backgroundColor: AppColors.botanicalGreen,
          ),
        );
      } else {
        final error = context.read<OwnerProvider>().ordersError ?? 'Failed to update order.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmPayment(NurseryOrder order, PaymentStatusEnum newStatus) async {
    final isPaying = newStatus == PaymentStatusEnum.paid;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPaying ? 'Confirm Payment Received?' : 'Mark Payment as Failed?'),
        content: Text(
          isPaying
              ? 'Have you verified the transfer of ₹${order.total.toStringAsFixed(2)} in your UPI/bank app?\n\nThis will record your owner account as the verifier and advance the order.'
              : 'Are you sure you want to mark this payment as Failed? The customer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaying ? AppColors.botanicalGreen : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isPaying ? 'Verify & Confirm' : 'Mark Failed'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<OwnerProvider>().confirmOrderPayment(
            order.id,
            newStatus,
            note: isPaying ? 'Owner verified UPI / manual payment.' : 'Owner rejected payment proof.',
          );
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPaying ? 'Payment confirmed for #${order.shortId}!' : 'Payment marked failed.'),
            backgroundColor: isPaying ? AppColors.botanicalGreen : AppColors.error,
          ),
        );
      } else {
        final error = context.read<OwnerProvider>().ordersError ?? 'Failed to update payment status.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailsModal(NurseryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.shortId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 16),

            // Contact & Delivery Card
            _buildInfoCard(
              title: 'Customer & Delivery Info',
              icon: Icons.person_outline,
              children: [
                _buildDetailRow('Customer Name', order.displayCustomerName),
                _buildDetailRow('Phone Number', order.displayCustomerPhone),
                _buildDetailRow('Fulfillment', order.fulfillmentType.label),
                if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                  _buildDetailRow('Address', order.deliveryAddress!),
                if (order.notes != null && order.notes!.isNotEmpty)
                  _buildDetailRow('Notes', order.notes!),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Verification Info Card
            _buildInfoCard(
              title: 'Payment Details',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildDetailRow('Payment Method', order.paymentMethod.label),
                _buildDetailRow('Payment Status', order.paymentStatus.label),
                if (order.paymentRef != null && order.paymentRef!.isNotEmpty)
                  _buildDetailRow('UPI Ref / UTR', order.paymentRef!),
                if (order.paymentConfirmedAt != null)
                  _buildDetailRow(
                    'Verified At',
                    _dateFormat.format(order.paymentConfirmedAt!.toLocal()),
                  ),
                if (order.paymentProofUrl != null && order.paymentProofUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Payment Screenshot Proof:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showImageDialog(order.paymentProofUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: order.paymentProofUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Audit Timeline
            if (order.statusHistory != null && order.statusHistory!.isNotEmpty) ...[
              _buildInfoCard(
                title: 'Audit & Transition History',
                icon: Icons.history_rounded,
                children: [
                  ...order.statusHistory!.map((entry) {
                    final e = entry as Map<String, dynamic>;
                    final ts = e['timestamp'] != null ? DateTime.tryParse(e['timestamp'].toString()) : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.botanicalGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: ${e['status'] ?? ''} • Payment: ${e['paymentStatus'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                if (e['note'] != null)
                                  Text('${e['note']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                if (ts != null)
                                  Text(
                                    _dateFormat.format(ts.toLocal()),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.botanicalGreen),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (owner.nursery != null)
              Text(owner.nursery!.name, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh orders',
            onPressed: () => owner.fetchOwnerOrders(refresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => owner.fetchOwnerOrders(refresh: true),
        child: Column(
          children: [
            _buildFilterBar(owner),
            Expanded(child: _buildOrdersList(owner)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(OwnerProvider owner) {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': owner.orders.length},
      {
        'key': 'NEEDS_PAYMENT',
        'label': 'Verify Payment',
        'count': owner.orders.where((o) => o.paymentStatus == PaymentStatusEnum.submitted).length,
      },
      {
        'key': 'PENDING_CONFIRMATION',
        'label': 'Pending Approval',
        'count': owner.orders.where((o) => o.status == OrderStatusEnum.pendingConfirmation).length,
      },
      {
        'key': 'ACCEPTED',
        'label': 'Accepted',
        'count': owner.orders.where((o) => o.status == OrderStatusEnum.accepted).length,
      },
      {
        'key': 'PREPARING',
        'label': 'Preparing',
        'count': owner.orders.where((o) => o.status == OrderStatusEnum.preparing).length,
      },
      {
        'key': 'READY_FOR_PICKUP',
        'label': 'Ready for Pickup',
        'count': owner.orders.where((o) => o.status == OrderStatusEnum.readyForPickup).length,
      },
      {
        'key': 'COMPLETED',
        'label': 'Completed',
        'count': owner.orders.where((o) => o.status == OrderStatusEnum.completed).length,
      },
      {
        'key': 'CANCELLED',
        'label': 'Cancelled',
        'count': owner.orders.where((o) => o.status == OrderStatusEnum.cancelled || o.status == OrderStatusEnum.rejected).length,
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((f) {
            final isSelected = owner.orderFilter == f['key'];
            final count = f['count'] as int;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f['label'] as String),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.botanicalGreenDark : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selectedColor: AppColors.botanicalGreenLight,
                checkmarkColor: AppColors.botanicalGreenDark,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.botanicalGreenDark : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => owner.setOrderFilter(f['key'] as String),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList(OwnerProvider owner) {
    if (owner.isOrdersLoading && owner.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (owner.ordersError != null && owner.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(owner.ordersError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => owner.fetchOwnerOrders(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final orders = owner.filteredOrders;

    if (orders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey[100],
                  child: const Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('No Orders Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  owner.orderFilter == 'all'
                      ? 'No incoming customer orders have been received yet.'
                      : 'No orders found matching this filter.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildOrderCard(NurseryOrder order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOrderDetailsModal(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER #${order.shortId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                      ),
                      if (order.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _dateFormat.format(order.createdAt!.toLocal()),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),

              const SizedBox(height: 10),

              // Badges Row: Payment Method, Fulfillment, Payment Status
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildPaymentStatusChip(order.paymentStatus),
                  _buildSmallBadge(
                    order.paymentMethod.label,
                    order.paymentMethod.icon,
                    const Color(0xFF6B7280),
                    const Color(0xFFF3F4F6),
                  ),
                  _buildSmallBadge(
                    order.fulfillmentType.label,
                    order.fulfillmentType.icon,
                    const Color(0xFF4B5563),
                    const Color(0xFFF3F4F6),
                  ),
                ],
              ),

              const Divider(height: 20),

              // Customer Info with Tap-to-Copy Phone
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.botanicalGreenLight,
                    child: Text(
                      order.displayCustomerName.isNotEmpty ? order.displayCustomerName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.botanicalGreenDark, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.displayCustomerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        Text(order.displayCustomerPhone, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                    tooltip: 'Copy customer phone',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: order.displayCustomerPhone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number copied'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Items Summary Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: item.plant?.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: item.plant!.imageUrl!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                  )
                                : Container(width: 32, height: 32, color: Colors.grey[200]),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.plant?.name ?? 'Plant',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('x${item.quantity}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Text('₹${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.totalItemCount} items', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    'Total: ₹${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.botanicalGreenDark),
                  ),
                ],
              ),

              // ── Payment Verification Action Box ──
              if (order.paymentStatus == PaymentStatusEnum.submitted ||
                  (order.paymentMethod == PaymentMethodEnum.upi && order.paymentStatus == PaymentStatusEnum.pending)) ...[
                const Divider(height: 20),
                _buildPaymentVerificationReviewBox(order),
              ],

              // ── Fulfillment Lifecycle Action Buttons ──
              if (order.status != OrderStatusEnum.completed &&
                  order.status != OrderStatusEnum.cancelled &&
                  order.status != OrderStatusEnum.rejected) ...[
                const Divider(height: 20),
                _buildLifecycleActions(order),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentVerificationReviewBox(NurseryOrder order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.botanicalGreen),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Payment Review & Verification',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.botanicalGreenDark),
                ),
              ),
              if (order.paymentProofUrl != null)
                TextButton.icon(
                  onPressed: () => _showImageDialog(order.paymentProofUrl!),
                  icon: const Icon(Icons.image_outlined, size: 16),
                  label: const Text('View Proof', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          if (order.paymentRef != null && order.paymentRef!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'UTR / Reference: ${order.paymentRef}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmPayment(order, PaymentStatusEnum.failed),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Payment Failed', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmPayment(order, PaymentStatusEnum.paid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.botanicalGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Verify & Confirm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleActions(NurseryOrder order) {
    switch (order.status) {
      case OrderStatusEnum.pendingConfirmation:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _changeStatus(order, OrderStatusEnum.rejected, 'Reject', customNote: 'Rejected by nursery owner.'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Reject Order'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _changeStatus(order, OrderStatusEnum.accepted, 'Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.botanicalGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Accept Order'),
              ),
            ),
          ],
        );

      case OrderStatusEnum.accepted:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _changeStatus(order, OrderStatusEnum.preparing, 'Start Preparing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.inventory_2_outlined, size: 16),
            label: const Text('Start Preparing Order'),
          ),
        );

      case OrderStatusEnum.preparing:
        final isPickup = order.fulfillmentType == FulfillmentTypeEnum.pickup;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _changeStatus(
              order,
              isPickup ? OrderStatusEnum.readyForPickup : OrderStatusEnum.outForDelivery,
              isPickup ? 'Mark Ready for Pickup' : 'Mark Out for Delivery',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPickup ? const Color(0xFF0D9488) : const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            icon: Icon(isPickup ? Icons.store_mall_directory_outlined : Icons.local_shipping_outlined, size: 16),
            label: Text(isPickup ? 'Ready for Customer Pickup' : 'Send Out for Delivery'),
          ),
        );

      case OrderStatusEnum.readyForPickup:
      case OrderStatusEnum.outForDelivery:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _changeStatus(order, OrderStatusEnum.completed, 'Complete Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.botanicalGreen,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.task_alt_rounded, size: 16),
            label: const Text('Mark Order Fulfilled & Completed'),
          ),
        );

      case OrderStatusEnum.completed:
      case OrderStatusEnum.rejected:
      case OrderStatusEnum.cancelled:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusBadge(OrderStatusEnum status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(status.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: status.color)),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatusEnum status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.lightColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(status.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: status.color)),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String label, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
