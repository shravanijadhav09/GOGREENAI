import 'package:flutter_test/flutter_test.dart';
import 'package:gogreenai/features/plants/models/plant.dart';

void main() {
  group('Plant Model', () {
    test('parses from backend json with care and recommendation specs correctly', () {
      final json = {
        'id': 'plant_999',
        'name': 'Monstera Deliciosa',
        'description': 'Iconic split-leaf tropical philodendron',
        'price': '34.50',
        'stock': 12,
        'imageUrl': 'https://res.cloudinary.com/demo/image/upload/monstera.jpg',
        'category': 'Indoor & Foliage',
        'tags': ['tropical', 'statement-plant', 'easy-care'],
        'isActive': true,
        'sunlight': 'INDIRECT',
        'watering': 'MEDIUM',
        'careDifficulty': 'EASY',
        'isIndoor': true,
        'isOutdoor': false,
        'isPetSafe': false,
        'sizeCm': 75,
        'climate': ['tropical', 'humid'],
        'nurseryId': 'nursery_123',
      };

      final plant = Plant.fromJson(json);

      expect(plant.id, 'plant_999');
      expect(plant.name, 'Monstera Deliciosa');
      expect(plant.price, 34.50);
      expect(plant.stock, 12);
      expect(plant.inStock, true);
      expect(plant.sunlight, 'INDIRECT');
      expect(plant.watering, 'MEDIUM');
      expect(plant.careDifficulty, 'EASY');
      expect(plant.isIndoor, true);
      expect(plant.isOutdoor, false);
      expect(plant.isPetSafe, false);
      expect(plant.sizeCm, 75);
      expect(plant.placementLabel, 'Indoor');
      expect(plant.tags, ['tropical', 'statement-plant', 'easy-care']);
      expect(plant.climate, ['tropical', 'humid']);
      expect(plant.nurseryId, 'nursery_123');
    });

    test('copyWith modifies attributes properly without side-effects', () {
      final plant = Plant(
        id: 'p_1',
        name: 'Snake Plant',
        price: 19.99,
        stock: 5,
        nurseryId: 'n_1',
      );

      final updated = plant.copyWith(
        stock: 0,
        isActive: false,
        price: 22.00,
      );

      expect(updated.stock, 0);
      expect(updated.inStock, false);
      expect(updated.isActive, false);
      expect(updated.price, 22.00);
      expect(plant.stock, 5);
      expect(plant.inStock, true);
    });
  });
}
