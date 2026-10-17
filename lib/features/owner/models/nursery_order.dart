import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum OrderStatusEnum {
  pendingConfirmation,
  accepted,
  rejected,
  preparing,
  readyForPickup,
  outForDelivery,
  completed,
  cancelled;

  static OrderStatusEnum fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'PENDING_CONFIRMATION':
      case 'PENDING':
        return OrderStatusEnum.pendingConfirmation;
      case 'ACCEPTED':
      case 'CONFIRMED':
        return OrderStatusEnum.accepted;
      case 'REJECTED':
        return OrderStatusEnum.rejected;
      case 'PREPARING':
        return OrderStatusEnum.preparing;
      case 'READY_FOR_PICKUP':
        return OrderStatusEnum.readyForPickup;
      case 'OUT_FOR_DELIVERY':
      case 'SHIPPED':
        return OrderStatusEnum.outForDelivery;
      case 'COMPLETED':
      case 'DELIVERED':
        return OrderStatusEnum.completed;
      case 'CANCELLED':
        return OrderStatusEnum.cancelled;
      default:
        return OrderStatusEnum.pendingConfirmation;
    }
  }

  String get apiValue {
    switch (this) {
      case OrderStatusEnum.pendingConfirmation:
        return 'PENDING_CONFIRMATION';
      case OrderStatusEnum.accepted:
        return 'ACCEPTED';
      case OrderStatusEnum.rejected:
        return 'REJECTED';
      case OrderStatusEnum.preparing:
        return 'PREPARING';
      case OrderStatusEnum.readyForPickup:
        return 'READY_FOR_PICKUP';
      case OrderStatusEnum.outForDelivery:
        return 'OUT_FOR_DELIVERY';
      case OrderStatusEnum.completed:
        return 'COMPLETED';
      case OrderStatusEnum.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case OrderStatusEnum.pendingConfirmation:
        return 'Pending Approval';
      case OrderStatusEnum.accepted:
        return 'Accepted';
      case OrderStatusEnum.rejected:
        return 'Rejected';
      case OrderStatusEnum.preparing:
        return 'Preparing';
      case OrderStatusEnum.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatusEnum.outForDelivery:
        return 'Out for Delivery';
      case OrderStatusEnum.completed:
        return 'Completed';
      case OrderStatusEnum.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatusEnum.pendingConfirmation:
        return AppColors.warning;
      case OrderStatusEnum.accepted:
        return AppColors.primaryBlue;
      case OrderStatusEnum.rejected:
        return AppColors.error;
      case OrderStatusEnum.preparing:
        return const Color(0xFF8B5CF6);
      case OrderStatusEnum.readyForPickup:
        return const Color(0xFF0D9488);
      case OrderStatusEnum.outForDelivery:
        return const Color(0xFF6366F1);
      case OrderStatusEnum.completed:
        return AppColors.botanicalGreen;
      case OrderStatusEnum.cancelled:
        return AppColors.error;
    }
  }

  Color get lightColor {
    switch (this) {
      case OrderStatusEnum.pendingConfirmation:
        return const Color(0xFFFEF3C7);
      case OrderStatusEnum.accepted:
        return AppColors.primaryBlueLight;
      case OrderStatusEnum.rejected:
        return const Color(0xFFFEE2E2);
      case OrderStatusEnum.preparing:
        return const Color(0xFFEDE9FE);
      case OrderStatusEnum.readyForPickup:
        return const Color(0xFFCCFBF1);
      case OrderStatusEnum.outForDelivery:
        return const Color(0xFFE0E7FF);
      case OrderStatusEnum.completed:
        return AppColors.botanicalGreenLight;
      case OrderStatusEnum.cancelled:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatusEnum.pendingConfirmation:
        return Icons.hourglass_top_rounded;
      case OrderStatusEnum.accepted:
        return Icons.check_circle_outline_rounded;
      case OrderStatusEnum.rejected:
        return Icons.highlight_off_rounded;
      case OrderStatusEnum.preparing:
        return Icons.inventory_2_outlined;
      case OrderStatusEnum.readyForPickup:
        return Icons.store_mall_directory_outlined;
      case OrderStatusEnum.outForDelivery:
        return Icons.local_shipping_outlined;
      case OrderStatusEnum.completed:
        return Icons.task_alt_rounded;
      case OrderStatusEnum.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

enum PaymentStatusEnum {
  pending,
  submitted,
  paid,
  failed,
  refunded;

  static PaymentStatusEnum fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'SUBMITTED':
        return PaymentStatusEnum.submitted;
      case 'PAID':
        return PaymentStatusEnum.paid;
      case 'FAILED':
        return PaymentStatusEnum.failed;
      case 'REFUNDED':
        return PaymentStatusEnum.refunded;
      case 'PENDING':
      default:
        return PaymentStatusEnum.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentStatusEnum.pending:
        return 'PENDING';
      case PaymentStatusEnum.submitted:
        return 'SUBMITTED';
      case PaymentStatusEnum.paid:
        return 'PAID';
      case PaymentStatusEnum.failed:
        return 'FAILED';
      case PaymentStatusEnum.refunded:
        return 'REFUNDED';
    }
  }

  String get label {
    switch (this) {
      case PaymentStatusEnum.pending:
        return 'Payment Pending';
      case PaymentStatusEnum.submitted:
        return 'Proof Submitted';
      case PaymentStatusEnum.paid:
        return 'Paid & Verified';
      case PaymentStatusEnum.failed:
        return 'Payment Failed';
      case PaymentStatusEnum.refunded:
        return 'Refunded';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatusEnum.pending:
        return const Color(0xFFF59E0B);
      case PaymentStatusEnum.submitted:
        return const Color(0xFF2563EB);
      case PaymentStatusEnum.paid:
        return AppColors.botanicalGreen;
      case PaymentStatusEnum.failed:
        return AppColors.error;
      case PaymentStatusEnum.refunded:
        return const Color(0xFF9333EA);
    }
  }

  Color get lightColor {
    switch (this) {
      case PaymentStatusEnum.pending:
        return const Color(0xFFFEF3C7);
      case PaymentStatusEnum.submitted:
        return const Color(0xFFDBEAFE);
      case PaymentStatusEnum.paid:
        return AppColors.botanicalGreenLight;
      case PaymentStatusEnum.failed:
        return const Color(0xFFFEE2E2);
      case PaymentStatusEnum.refunded:
        return const Color(0xFFF3E8FF);
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatusEnum.pending:
        return Icons.schedule_rounded;
      case PaymentStatusEnum.submitted:
        return Icons.receipt_long_rounded;
      case PaymentStatusEnum.paid:
        return Icons.verified_rounded;
      case PaymentStatusEnum.failed:
        return Icons.error_outline_rounded;
      case PaymentStatusEnum.refunded:
        return Icons.undo_rounded;
    }
  }
}

enum PaymentMethodEnum {
  upi,
  payAtPickup,
  cod;

  static PaymentMethodEnum fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'UPI':
        return PaymentMethodEnum.upi;
      case 'COD':
        return PaymentMethodEnum.cod;
      case 'PAY_AT_PICKUP':
      default:
        return PaymentMethodEnum.payAtPickup;
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethodEnum.upi:
        return 'UPI';
      case PaymentMethodEnum.payAtPickup:
        return 'PAY_AT_PICKUP';
      case PaymentMethodEnum.cod:
        return 'COD';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethodEnum.upi:
        return 'UPI Transfer';
      case PaymentMethodEnum.payAtPickup:
        return 'Pay at Pickup';
      case PaymentMethodEnum.cod:
        return 'Cash on Delivery';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethodEnum.upi:
        return Icons.qr_code_rounded;
      case PaymentMethodEnum.payAtPickup:
        return Icons.storefront_rounded;
      case PaymentMethodEnum.cod:
        return Icons.payments_outlined;
    }
  }
}

enum FulfillmentTypeEnum {
  pickup,
  delivery;

  static FulfillmentTypeEnum fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'DELIVERY':
        return FulfillmentTypeEnum.delivery;
      case 'PICKUP':
      default:
        return FulfillmentTypeEnum.pickup;
    }
  }

  String get apiValue {
    switch (this) {
      case FulfillmentTypeEnum.pickup:
        return 'PICKUP';
      case FulfillmentTypeEnum.delivery:
        return 'DELIVERY';
    }
  }

  String get label {
    switch (this) {
      case FulfillmentTypeEnum.pickup:
        return 'Pick up at Nursery';
      case FulfillmentTypeEnum.delivery:
        return 'Home Delivery';
    }
  }

  IconData get icon {
    switch (this) {
      case FulfillmentTypeEnum.pickup:
        return Icons.directions_walk_rounded;
      case FulfillmentTypeEnum.delivery:
        return Icons.local_shipping_outlined;
    }
  }
}

class OrderCustomer {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  const OrderCustomer({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty).toList();
    if (parts.isEmpty) return email ?? 'Customer';
    return parts.join(' ');
  }

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

class OrderPlant {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  final String? category;

  const OrderPlant({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.category,
  });

  factory OrderPlant.fromJson(Map<String, dynamic> json) {
    return OrderPlant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Plant',
      imageUrl: json['imageUrl'] as String?,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'price': price,
      if (category != null) 'category': category,
    };
  }
}

class NurseryOrderItem {
  final String id;
  final int quantity;
  final double price;
  final String plantId;
  final OrderPlant? plant;

  const NurseryOrderItem({
    required this.id,
    required this.quantity,
    required this.price,
    required this.plantId,
    this.plant,
  });

  double get subtotal => price * quantity;
  String get plantName => plant?.name ?? 'Plant';
  String? get plantImageUrl => plant?.imageUrl;

  factory NurseryOrderItem.fromJson(Map<String, dynamic> json) {
    return NurseryOrderItem(
      id: json['id'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      plantId: json['plantId'] as String? ?? '',
      plant: json['plant'] != null
          ? OrderPlant.fromJson(json['plant'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'price': price,
      'plantId': plantId,
      if (plant != null) 'plant': plant!.toJson(),
    };
  }
}

class NurseryOrder {
  final String id;
  final OrderStatusEnum status;
  final PaymentStatusEnum paymentStatus;
  final PaymentMethodEnum paymentMethod;
  final FulfillmentTypeEnum fulfillmentType;
  final double total;
  final String customerId;
  final String nurseryId;
  final OrderCustomer? customer;
  final List<NurseryOrderItem> items;
  final String? paymentRef;
  final String? paymentProofUrl;
  final DateTime? paymentConfirmedAt;
  final String? paymentConfirmedBy;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? notes;
  final List<dynamic>? statusHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NurseryOrder({
    required this.id,
    required this.status,
    this.paymentStatus = PaymentStatusEnum.pending,
    this.paymentMethod = PaymentMethodEnum.payAtPickup,
    this.fulfillmentType = FulfillmentTypeEnum.pickup,
    required this.total,
    required this.customerId,
    required this.nurseryId,
    this.customer,
    this.items = const [],
    this.paymentRef,
    this.paymentProofUrl,
    this.paymentConfirmedAt,
    this.paymentConfirmedBy,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.notes,
    this.statusHistory,
    this.createdAt,
    this.updatedAt,
  });

  String get shortId => id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusDisplay => status.label;
  String get paymentStatusDisplay => paymentStatus.label;
  String get paymentMethodDisplay => paymentMethod.label;

  String get displayCustomerName {
    if (customerName != null && customerName!.trim().isNotEmpty) {
      return customerName!;
    }
    return customer?.fullName ?? 'Customer';
  }

  String get displayCustomerPhone {
    if (customerPhone != null && customerPhone!.trim().isNotEmpty) {
      return customerPhone!;
    }
    return customer?.phone ?? 'Not provided';
  }

  factory NurseryOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return NurseryOrder(
      id: json['id'] as String? ?? '',
      status: OrderStatusEnum.fromString(json['status'] as String?),
      paymentStatus: PaymentStatusEnum.fromString(json['paymentStatus'] as String?),
      paymentMethod: PaymentMethodEnum.fromString(json['paymentMethod'] as String?),
      fulfillmentType: FulfillmentTypeEnum.fromString(json['fulfillmentType'] as String?),
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      customerId: json['customerId'] as String? ?? '',
      nurseryId: json['nurseryId'] as String? ?? '',
      customer: json['customer'] != null
          ? OrderCustomer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      items: rawItems
          .map((i) => NurseryOrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      paymentRef: json['paymentRef'] as String?,
      paymentProofUrl: json['paymentProofUrl'] as String?,
      paymentConfirmedAt: json['paymentConfirmedAt'] != null
          ? DateTime.tryParse(json['paymentConfirmedAt'].toString())
          : null,
      paymentConfirmedBy: json['paymentConfirmedBy'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      notes: json['notes'] as String?,
      statusHistory: json['statusHistory'] as List<dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.apiValue,
      'paymentStatus': paymentStatus.apiValue,
      'paymentMethod': paymentMethod.apiValue,
      'fulfillmentType': fulfillmentType.apiValue,
      'total': total,
      'customerId': customerId,
      'nurseryId': nurseryId,
      if (customer != null) 'customer': customer!.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      if (paymentRef != null) 'paymentRef': paymentRef,
      if (paymentProofUrl != null) 'paymentProofUrl': paymentProofUrl,
      if (paymentConfirmedAt != null) 'paymentConfirmedAt': paymentConfirmedAt!.toIso8601String(),
      if (paymentConfirmedBy != null) 'paymentConfirmedBy': paymentConfirmedBy,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (notes != null) 'notes': notes,
      if (statusHistory != null) 'statusHistory': statusHistory,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  NurseryOrder copyWith({
    String? id,
    OrderStatusEnum? status,
    PaymentStatusEnum? paymentStatus,
    PaymentMethodEnum? paymentMethod,
    FulfillmentTypeEnum? fulfillmentType,
    double? total,
    String? customerId,
    String? nurseryId,
    OrderCustomer? customer,
    List<NurseryOrderItem>? items,
    String? paymentRef,
    String? paymentProofUrl,
    DateTime? paymentConfirmedAt,
    String? paymentConfirmedBy,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? notes,
    List<dynamic>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NurseryOrder(
      id: id ?? this.id,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      total: total ?? this.total,
      customerId: customerId ?? this.customerId,
      nurseryId: nurseryId ?? this.nurseryId,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      paymentRef: paymentRef ?? this.paymentRef,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentConfirmedAt: paymentConfirmedAt ?? this.paymentConfirmedAt,
      paymentConfirmedBy: paymentConfirmedBy ?? this.paymentConfirmedBy,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

typedef OrderItemModel = NurseryOrderItem;
