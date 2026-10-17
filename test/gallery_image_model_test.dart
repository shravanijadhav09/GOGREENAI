import 'package:flutter_test/flutter_test.dart';
import 'package:gogreenai/features/owner/models/gallery_image.dart';

void main() {
  group('GalleryImage Model Tests', () {
    test('fromJson and toJson should correctly serialize and deserialize', () {
      final json = {
        'id': 'img_123',
        'url': 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        'publicId': 'sample_123',
        'caption': 'Our greenhouse orchids',
        'category': 'Greenhouse',
        'sortOrder': 2,
        'nurseryId': 'nurs_456',
        'createdAt': '2026-10-16T12:00:00.000Z',
        'updatedAt': '2026-10-16T12:00:00.000Z',
      };

      final image = GalleryImage.fromJson(json);

      expect(image.id, 'img_123');
      expect(image.url, 'https://res.cloudinary.com/demo/image/upload/sample.jpg');
      expect(image.publicId, 'sample_123');
      expect(image.caption, 'Our greenhouse orchids');
      expect(image.category, 'Greenhouse');
      expect(image.sortOrder, 2);
      expect(image.nurseryId, 'nurs_456');
      expect(image.createdAt, isNotNull);

      final serialized = image.toJson();
      expect(serialized['id'], 'img_123');
      expect(serialized['url'], 'https://res.cloudinary.com/demo/image/upload/sample.jpg');
      expect(serialized['caption'], 'Our greenhouse orchids');
      expect(serialized['category'], 'Greenhouse');
      expect(serialized['sortOrder'], 2);
    });

    test('copyWith should allow updating specific fields', () {
      const original = GalleryImage(
        id: 'img_1',
        url: 'https://example.com/1.jpg',
        nurseryId: 'nurs_1',
        caption: 'Old caption',
        category: 'Old category',
      );

      final updated = original.copyWith(
        caption: 'New caption',
        category: 'Greenhouse',
        sortOrder: 5,
      );

      expect(updated.id, original.id);
      expect(updated.url, original.url);
      expect(updated.nurseryId, original.nurseryId);
      expect(updated.caption, 'New caption');
      expect(updated.category, 'Greenhouse');
      expect(updated.sortOrder, 5);
    });
  });
}
