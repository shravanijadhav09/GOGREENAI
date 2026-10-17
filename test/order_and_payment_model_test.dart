import 'package:flutter_test/flutter_test.dart';
import 'package:gogreenai/features/nurseries/models/nursery.dart';
import 'package:gogreenai/features/owner/models/nursery_order.dart';

void main() {
  group('Nursery Payment Settings Model Tests', () {
    test('parses payment settings from json', () {
      final json = {
        'id': 'nurs_123',
        'name': 'Green Planet',
        'upiId': 'greenplanet@okaxis',
        'upiQrUrl': 'https://res.cloudinary.com/demo/qr.png',
        'isUpiEnabled': true,
        'isPayAtPickupEnabled': true,
        'isCodEnabled': false,
      };

      final nursery = Nursery.fromJson(json);
      expect(nursery.id, 'nurs_123');
      expect(nursery.upiId, 'greenplanet@okaxis');
      expect(nursery.upiQrUrl, 'https://res.cloudinary.com/demo/qr.png');
      expect(nursery.isUpiEnabled, true);
      expect(nursery.isPayAtPickupEnabled, true);
      expect(nursery.isCodEnabled, false);
    });

    test('copyWith updates payment settings', () {
      final nursery = Nursery(id: 'n1', name: 'N1');
      final updated = nursery.copyWith(
        upiId: 'new@upi',
        isUpiEnabled: true,
      );
      expect(updated.upiId, 'new@upi');
      expect(updated.isUpiEnabled, true);
      expect(updated.id, 'n1');
    });
  });

  group('NurseryOrder Model & Enums Tests', () {
    test('parses order with payment status, methods, and proof', () {
      final json = {
        'id': 'ord_987654321',
        'status': 'PENDING_CONFIRMATION',
        'paymentStatus': 'SUBMITTED',
        'paymentMethod': 'UPI',
        'fulfillmentType': 'DELIVERY',
        'total': '950.00',
        'customerId': 'cust_1',
        'nurseryId': 'nurs_1',
        'paymentRef': 'UTR1234567890',
        'paymentProofUrl': 'https://res.cloudinary.com/demo/proof.png',
        'customerName': 'John Doe',
        'customerPhone': '9876543210',
        'deliveryAddress': 'Flat 402, Green Avenue, Pune',
        'items': [
          {
            'id': 'item_1',
            'quantity': 2,
            'price': '475.00',
            'plantId': 'plant_1',
            'plant': {
              'id': 'plant_1',
              'name': 'Fiddle Leaf Fig',
              'price': '475.00',
            },
          }
        ],
      };

      final order = NurseryOrder.fromJson(json);
      expect(order.id, 'ord_987654321');
      expect(order.status, OrderStatusEnum.pendingConfirmation);
      expect(order.paymentStatus, PaymentStatusEnum.submitted);
      expect(order.paymentMethod, PaymentMethodEnum.upi);
      expect(order.fulfillmentType, FulfillmentTypeEnum.delivery);
      expect(order.total, 950.00);
      expect(order.paymentRef, 'UTR1234567890');
      expect(order.items.length, 1);
      expect(order.items.first.subtotal, 950.00);
      expect(order.displayCustomerName, 'John Doe');
      expect(order.displayCustomerPhone, '9876543210');
    });

    test('serializes and deserializes payment and order status enum', () {
      expect(OrderStatusEnum.fromString('PENDING_CONFIRMATION'), OrderStatusEnum.pendingConfirmation);
      expect(OrderStatusEnum.fromString('ACCEPTED'), OrderStatusEnum.accepted);
      expect(OrderStatusEnum.fromString('PREPARING'), OrderStatusEnum.preparing);
      expect(OrderStatusEnum.fromString('READY_FOR_PICKUP'), OrderStatusEnum.readyForPickup);
      expect(OrderStatusEnum.fromString('OUT_FOR_DELIVERY'), OrderStatusEnum.outForDelivery);
      expect(OrderStatusEnum.fromString('COMPLETED'), OrderStatusEnum.completed);
      expect(OrderStatusEnum.fromString('REJECTED'), OrderStatusEnum.rejected);

      expect(PaymentStatusEnum.fromString('PENDING'), PaymentStatusEnum.pending);
      expect(PaymentStatusEnum.fromString('SUBMITTED'), PaymentStatusEnum.submitted);
      expect(PaymentStatusEnum.fromString('PAID'), PaymentStatusEnum.paid);
      expect(PaymentStatusEnum.fromString('FAILED'), PaymentStatusEnum.failed);
    });
  });
}
