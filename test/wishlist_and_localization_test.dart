import 'package:flutter_test/flutter_test.dart';
import 'package:gogreenai/providers/wishlist_provider.dart';
import 'package:gogreenai/providers/language_provider.dart';
import 'package:gogreenai/features/plants/models/plant.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WishlistProvider Tests', () {
    late WishlistProvider provider;

    final samplePlant1 = Plant(
      id: 'plant-1',
      name: 'Monstera Deliciosa',
      price: 499.0,
      stock: 5,
      nurseryId: 'nursery-1',
      category: 'Indoor Plants',
      isIndoor: true,
      isOutdoor: false,
    );

    final samplePlant2 = Plant(
      id: 'plant-2',
      name: 'Tulsi Holy Basil',
      price: 99.0,
      stock: 12,
      nurseryId: 'nursery-1',
      category: 'Medicinal Plants',
      isIndoor: false,
      isOutdoor: true,
      tags: ['medicinal', 'ayurvedic'],
    );

    setUp(() {
      provider = WishlistProvider();
    });

    test('Initial wishlist is empty', () {
      expect(provider.isEmpty, isTrue);
      expect(provider.count, equals(0));
      expect(provider.contains('plant-1'), isFalse);
    });

    test('Toggle adds and removes plant item', () {
      provider.toggle(samplePlant1);
      expect(provider.contains('plant-1'), isTrue);
      expect(provider.count, equals(1));

      provider.toggle(samplePlant1);
      expect(provider.contains('plant-1'), isFalse);
      expect(provider.count, equals(0));
    });

    test('Sync with plants updates prices and inventory real-time', () {
      provider.add(samplePlant1);

      // Simulate updated plant data from backend with new price and stock
      final updatedPlant1 = Plant(
        id: 'plant-1',
        name: 'Monstera Deliciosa',
        price: 549.0,
        stock: 0, // out of stock now
        nurseryId: 'nursery-1',
      );

      provider.syncWithPlants([updatedPlant1, samplePlant2]);

      final item = provider.items.firstWhere((p) => p.id == 'plant-1');
      expect(item.price, equals(549.0));
      expect(item.isOutOfStock, isTrue);
    });

    test('Clear empties all items', () {
      provider.add(samplePlant1);
      provider.add(samplePlant2);
      expect(provider.count, equals(2));

      provider.clear();
      expect(provider.isEmpty, isTrue);
      expect(provider.count, equals(0));
    });
  });

  group('LanguageProvider Tests', () {
    late LanguageProvider provider;

    setUp(() {
      provider = LanguageProvider();
    });

    test('Default language is English', () {
      expect(provider.localeCode, equals('en'));
      expect(provider.translate('nav_home'), equals('Home'));
      expect(provider.translate('nav_plants'), equals('Plants'));
    });

    test('Switching to Marathi provides accurate translations', () {
      provider.setLocale('mr');
      expect(provider.localeCode, equals('mr'));
      expect(provider.translate('nav_home'), equals('मुख्यपृष्ठ'));
      expect(provider.translate('nav_plants'), equals('वनस्पती'));
      expect(provider.translate('medicinal'), equals('औषधी वनस्पती 🌿'));
    });

    test('Switching to Hindi provides accurate translations', () {
      provider.setLocale('hi');
      expect(provider.localeCode, equals('hi'));
      expect(provider.translate('nav_home'), equals('होम'));
      expect(provider.translate('nav_plants'), equals('पौधे'));
      expect(provider.translate('medicinal'), equals('औषधीय पौधे 🌿'));
    });
  });
}
