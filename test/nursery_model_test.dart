import 'package:flutter_test/flutter_test.dart';
import 'package:gogreenai/features/nurseries/models/nursery.dart';

void main() {
  group('Nursery Model', () {
    test('parses from backend json with logoUrl correctly', () {
      final json = {
        'id': 'nursery_123',
        'name': 'Green Thumb Botanical Sanctuary',
        'description': 'A beautiful botanical garden and nursery',
        'address': '123 Botanical Ave',
        'city': 'Austin',
        'state': 'TX',
        'phone': '+1 555-019-2834',
        'logoUrl': 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        'isVerified': true,
        'isActive': true,
        '_count': {'plants': 15},
      };

      final nursery = Nursery.fromJson(json);

      expect(nursery.id, 'nursery_123');
      expect(nursery.name, 'Green Thumb Botanical Sanctuary');
      expect(nursery.logoUrl, 'https://res.cloudinary.com/demo/image/upload/sample.jpg');
      expect(nursery.imageUrl, 'https://res.cloudinary.com/demo/image/upload/sample.jpg');
      expect(nursery.city, 'Austin');
      expect(nursery.state, 'TX');
      expect(nursery.locationDisplay, 'Austin, TX');
      expect(nursery.isVerified, true);
      expect(nursery.isActive, true);
      expect(nursery.plantCount, 15);
    });

    test('copyWith updates fields without mutating original', () {
      final original = Nursery(
        id: 'n_1',
        name: 'Original Nursery',
        city: 'Austin',
        state: 'TX',
      );

      final updated = original.copyWith(
        name: 'Updated Nursery Name',
        description: 'New Description',
      );

      expect(updated.id, 'n_1');
      expect(updated.name, 'Updated Nursery Name');
      expect(updated.description, 'New Description');
      expect(updated.city, 'Austin');
      expect(original.name, 'Original Nursery');
    });
  });
}
