import 'package:flutter_test/flutter_test.dart';
import 'package:gogreenai/features/nurseries/models/nursery.dart';
import 'package:gogreenai/features/plants/models/plant.dart';
import 'package:gogreenai/providers/cart_provider.dart';

void main() {
  group('CartProvider Tests', () {
    late CartProvider cart;

    final plantNursery1 = Plant(
      id: 'p1',
      name: 'Monstera Deliciosa',
      price: 499.0,
      stock: 5,
      nurseryId: 'nursery-1',
      nurseryName: 'Green Paradise',
    );

    final plant2Nursery1 = Plant(
      id: 'p2',
      name: 'Snake Plant',
      price: 299.0,
      stock: 3,
      nurseryId: 'nursery-1',
      nurseryName: 'Green Paradise',
    );

    final plantNursery2 = Plant(
      id: 'p3',
      name: 'Fiddle Leaf Fig',
      price: 899.0,
      stock: 10,
      nurseryId: 'nursery-2',
      nurseryName: 'Urban Jungle',
    );

    setUp(() {
      cart = CartProvider();
    });

    test('Initial cart is empty with zero count and total', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.totalCount, 0);
      expect(cart.totalAmount, 0.0);
      expect(cart.currentNurseryId, isNull);
    });

    test('Add item from single nursery computes subtotal and total items', () {
      final success = cart.addItem(plantNursery1, quantity: 2);
      expect(success, isTrue);
      expect(cart.itemCount, 2);
      expect(cart.uniqueItemCount, 1);
      expect(cart.totalAmount, 998.0);
      expect(cart.currentNurseryId, 'nursery-1');

      // Add another item from same nursery
      final success2 = cart.addItem(plant2Nursery1, quantity: 1);
      expect(success2, isTrue);
      expect(cart.itemCount, 3);
      expect(cart.uniqueItemCount, 2);
      expect(cart.totalAmount, 998.0 + 299.0);
    });

    test('Prevents mixed-nursery checkout without forceClear', () {
      cart.addItem(plantNursery1, quantity: 1);
      expect(cart.currentNurseryId, 'nursery-1');

      // Attempting to add from nursery-2 should be rejected
      final added = cart.addItem(plantNursery2, quantity: 1, forceClear: false);
      expect(added, isFalse);
      expect(cart.itemCount, 1);
      expect(cart.currentNurseryId, 'nursery-1');

      // With forceClear: true, it resets and adds the new nursery's item
      final forceAdded = cart.addItem(plantNursery2, quantity: 2, forceClear: true);
      expect(forceAdded, isTrue);
      expect(cart.itemCount, 2);
      expect(cart.currentNurseryId, 'nursery-2');
      expect(cart.items.first.plant.id, 'p3');
    });

    test('Respects maximum available stock on addition and increment', () {
      // plantNursery1 has stock 5
      cart.addItem(plantNursery1, quantity: 4);
      expect(cart.getQuantity('p1'), 4);

      // Increment once -> reaches 5 (max)
      expect(cart.incrementQuantity('p1'), isTrue);
      expect(cart.getQuantity('p1'), 5);

      // Increment again -> should return false and stay at 5
      expect(cart.incrementQuantity('p1'), isFalse);
      expect(cart.getQuantity('p1'), 5);

      // Trying to add 10 should clamp to stock limit
      cart.updateQuantity('p1', 10);
      expect(cart.getQuantity('p1'), 5);
    });

    test('Quantity decrement removes item when reaching zero', () {
      cart.addItem(plantNursery1, quantity: 1);
      expect(cart.itemCount, 1);

      cart.decrementQuantity('p1');
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
    });

    test('Clear resets cart completely', () {
      cart.addItem(plantNursery1, quantity: 2);
      cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.currentNurseryId, isNull);
    });
  });

  group('Nursery Coordinates & Distance Calculation Tests', () {
    // Bengaluru MG Road: 12.9716, 77.5946
    // Bengaluru Whitefield: 12.9698, 77.7499 (~16.8 km away)
    final nurseryWithCoords = Nursery(
      id: 'n1',
      name: 'East Bengaluru Green Hub',
      latitude: 12.9698,
      longitude: 77.7499,
      city: 'Bengaluru',
      state: 'Karnataka',
    );

    final nurseryWithoutCoords = Nursery(
      id: 'n2',
      name: 'Mystic Garden',
      city: 'Bengaluru',
      state: 'Karnataka',
    );

    test('hasCoordinates accurately detects presence of lat/lng', () {
      expect(nurseryWithCoords.hasCoordinates, isTrue);
      expect(nurseryWithoutCoords.hasCoordinates, isFalse);
    });

    test('distanceFrom returns null if either nursery or user coordinates are missing', () {
      expect(nurseryWithoutCoords.distanceFrom(12.9716, 77.5946), isNull);
      expect(nurseryWithCoords.distanceFrom(null, 77.5946), isNull);
      expect(nurseryWithCoords.distanceFrom(12.9716, null), isNull);
    });

    test('distanceFrom calculates accurate straight-line distance via Haversine', () {
      final dist = nurseryWithCoords.distanceFrom(12.9716, 77.5946);
      expect(dist, isNotNull);
      // Distance between MG Road and Whitefield is approx 19.3 km
      expect(dist!, greaterThan(15.0));
      expect(dist, lessThan(22.0));
    });

    test('distanceDisplayFrom formats distances in meters and kilometers nicely', () {
      // Whitefield distance formatted in km
      final display = nurseryWithCoords.distanceDisplayFrom(12.9716, 77.5946);
      expect(display, contains('km'));

      // Same location formatted in meters
      final nearbyDisplay = nurseryWithCoords.distanceDisplayFrom(12.9699, 77.7500);
      expect(nearbyDisplay, contains('m'));
    });
  });

  group('Plant Catalogue & Multi-dimensional Filter Tests', () {
    final plantIndoorFlowering = Plant(
      id: 'p1',
      name: 'Peace Lily',
      category: 'Flowering',
      isIndoor: true,
      price: 350.0,
      stock: 10,
      tags: ['indoor', 'air-purifying'],
      nurseryId: 'n1',
    );

    final plantMedicinal = Plant(
      id: 'p2',
      name: 'Tulsi Holy Basil',
      category: 'Herbs',
      isOutdoor: true,
      price: 120.0,
      stock: 25,
      tags: ['medicinal', 'ayurvedic', 'herb'],
      nurseryId: 'n1',
    );

    final plantOutdoorBonsai = Plant(
      id: 'p3',
      name: 'Ficus Bonsai',
      category: 'Bonsai',
      isOutdoor: true,
      price: 1500.0,
      stock: 2,
      tags: ['outdoor', 'decorative'],
      nurseryId: 'n1',
    );

    final plantOutOfStock = Plant(
      id: 'p4',
      name: 'Rare Variegated Monstera',
      category: 'Foliage',
      isIndoor: true,
      price: 4500.0,
      stock: 0,
      tags: ['rare', 'indoor'],
      nurseryId: 'n1',
    );

    test('Plant tags and medicinal detection work correctly', () {
      expect(plantMedicinal.isMedicinal, isTrue);
      expect(plantIndoorFlowering.isMedicinal, isFalse);
      expect(plantIndoorFlowering.isIndoor, isTrue);
      expect(plantOutdoorBonsai.isOutdoor, isTrue);
      expect(plantOutOfStock.inStock, isFalse);
    });
  });
}
