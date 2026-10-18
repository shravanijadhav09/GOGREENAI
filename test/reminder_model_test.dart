import 'package:flutter_test/flutter_test.dart';
import 'package:gogreenai/features/reminders/models/plant_care_reminder.dart';

void main() {
  group('PlantCareReminder Model Tests', () {
    test('serializes and deserializes from JSON correctly', () {
      final now = DateTime.now();
      final reminder = PlantCareReminder(
        id: 'rem-1',
        plantName: 'Fiddle Leaf Fig',
        careType: CareType.watering,
        frequencyDays: 5,
        nextDueDate: now,
        notes: 'Check top 2 inches of soil.',
      );

      final json = reminder.toJson();
      final fromJson = PlantCareReminder.fromJson(json);

      expect(fromJson.id, equals('rem-1'));
      expect(fromJson.plantName, equals('Fiddle Leaf Fig'));
      expect(fromJson.careType, equals(CareType.watering));
      expect(fromJson.frequencyDays, equals(5));
      expect(fromJson.notes, equals('Check top 2 inches of soil.'));
      expect(fromJson.isDueToday, isTrue);
    });

    test('calculates overdue and due text accurately', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final overdueReminder = PlantCareReminder(
        id: 'rem-2',
        plantName: 'Aloe Vera',
        careType: CareType.watering,
        frequencyDays: 14,
        nextDueDate: pastDate,
      );

      expect(overdueReminder.isOverdue, isTrue);
      expect(overdueReminder.dueStatusText, contains('Overdue'));

      final futureDate = DateTime.now().add(const Duration(days: 3));
      final futureReminder = PlantCareReminder(
        id: 'rem-3',
        plantName: 'Snake Plant',
        careType: CareType.fertilizing,
        frequencyDays: 30,
        nextDueDate: futureDate,
      );

      expect(futureReminder.isOverdue, isFalse);
      expect(futureReminder.isDueToday, isFalse);
      expect(futureReminder.dueStatusText, equals('Due in 3 days'));
    });

    test('CareType parses and returns correct labels and emojis', () {
      expect(CareType.fromString('WATERING'), equals(CareType.watering));
      expect(CareType.fromString('fertilizing'), equals(CareType.fertilizing));
      expect(CareType.fromString('repotting'), equals(CareType.repotting));
      expect(CareType.fromString('pruning'), equals(CareType.pruning));
      expect(CareType.fromString(null), equals(CareType.watering));

      expect(CareType.watering.emoji, equals('💧'));
      expect(CareType.fertilizing.emoji, equals('🌿'));
      expect(CareType.repotting.emoji, equals('🪴'));
      expect(CareType.pruning.emoji, equals('✂️'));
    });
  });
}
