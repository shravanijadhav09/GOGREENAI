import 'package:flutter_test/flutter_test.dart';
import 'package:gogreenai/core/constants/india_locations.dart';
import 'package:gogreenai/features/ai/models/ai_models.dart';

void main() {
  group('AI Models Tests', () {
    test('PlantIdentificationResult parses valid JSON properly', () {
      final json = {
        'plantName': 'Monstera deliciosa',
        'commonName': 'Swiss Cheese Plant',
        'confidence': 'High',
        'characteristics': ['Large split leaves', 'Aerial roots'],
        'suggestedNextSteps': ['Place in indirect sunlight', 'Water weekly'],
        'careSummary': {
          'watering': 'Weekly',
          'sunlight': 'Bright indirect',
          'difficulty': 'Easy',
        },
      };

      final result = PlantIdentificationResult.fromJson(json);
      expect(result.plantName, 'Monstera deliciosa');
      expect(result.commonName, 'Swiss Cheese Plant');
      expect(result.confidence, 'High');
      expect(result.characteristics.length, 2);
      expect(result.careSummary?.watering, 'Weekly');
      expect(result.careSummary?.sunlight, 'Bright indirect');
      expect(result.careSummary?.difficulty, 'Easy');
    });

    test('PlantDiseaseDiagnosisResult parses valid JSON properly', () {
      final json = {
        'plantName': 'Tomato',
        'possibleDisease': 'Early Blight',
        'severity': 'Moderate',
        'observedSymptoms': ['Brown concentric spots on lower leaves'],
        'recommendedTreatments': ['Apply copper-based fungicide', 'Remove affected foliage'],
        'preventionMeasures': ['Avoid overhead watering', 'Ensure proper spacing'],
        'expertConsultationGuidance': 'Consult local agriculture extension if spreading rapidly.',
        'isEstimateNotice': 'AI estimate only — consult an agronomist before heavy chemical use.',
      };

      final result = PlantDiseaseDiagnosisResult.fromJson(json);
      expect(result.plantName, 'Tomato');
      expect(result.possibleDisease, 'Early Blight');
      expect(result.severity, 'Moderate');
      expect(result.observedSymptoms.length, 1);
      expect(result.recommendedTreatments.length, 2);
      expect(result.preventionMeasures.length, 2);
      expect(result.expertConsultationGuidance, contains('extension'));
    });

    test('PlantCareAdviceResult parses valid JSON properly', () {
      final json = {
        'plantName': 'Peace Lily',
        'shortAnswer': 'A resilient indoor flowering plant that thrives in filtered light.',
        'wateringGuidance': 'Keep moist, water every 4-5 days',
        'lightRequirements': 'Low to medium indirect light',
        'soilConditions': 'Well-draining potting mix',
        'careSteps': ['Wipe leaves periodically', 'Remove spent flowers'],
        'warnings': ['Mildly toxic to cats and dogs if ingested'],
      };

      final result = PlantCareAdviceResult.fromJson(json);
      expect(result.plantName, 'Peace Lily');
      expect(result.wateringGuidance, contains('4-5 days'));
      expect(result.careSteps.length, 2);
      expect(result.warnings.length, 1);
    });

    test('AiChatResult parses conversation response', () {
      final json = {
        'reply': 'Yes, snake plants are very drought tolerant and thrive on neglect.',
      };

      final result = AiChatResult.fromJson(json);
      expect(result.reply, contains('snake plants'));
    });

    test('DiseaseTreatmentResult parses treatment guide correctly', () {
      final json = {
        'plantName': 'Mint',
        'condition': 'Powdery Mildew',
        'urgency': 'Immediate',
        'immediateActions': ['Isolate plant', 'Prune infected leaves'],
        'organicTreatments': ['Spray diluted neem oil solution (0.5%)', 'Baking soda spray'],
        'environmentalAdjustments': ['Increase morning sunlight', 'Improve airflow'],
        'preventionMeasures': ['Avoid wetting leaves during watering'],
        'warnings': ['Do not spray in full direct afternoon sun to avoid foliage burn'],
      };

      final result = DiseaseTreatmentResult.fromJson(json);
      expect(result.plantName, 'Mint');
      expect(result.condition, 'Powdery Mildew');
      expect(result.urgency, 'Immediate');
      expect(result.immediateActions.length, 2);
      expect(result.organicTreatments.length, 2);
      expect(result.warnings.length, 1);
    });
  });

  group('India Locations Dataset Tests', () {
    test('IndiaLocations contains all major states and union territories', () {
      expect(IndiaLocations.states.contains('Maharashtra'), isTrue);
      expect(IndiaLocations.states.contains('Karnataka'), isTrue);
      expect(IndiaLocations.states.contains('Delhi (NCT)'), isTrue);
      expect(IndiaLocations.states.contains('Gujarat'), isTrue);
    });

    test('getCitiesForState returns appropriate cities for selected state', () {
      final mhCities = IndiaLocations.getCitiesForState('Maharashtra');
      expect(mhCities.contains('Mumbai'), isTrue);
      expect(mhCities.contains('Pune'), isTrue);
      expect(mhCities.contains('Nagpur'), isTrue);

      final kaCities = IndiaLocations.getCitiesForState('Karnataka');
      expect(kaCities.contains('Bengaluru'), isTrue);
      expect(kaCities.contains('Mysuru'), isTrue);
    });

    test('getCitiesForState returns empty list for null or invalid state', () {
      expect(IndiaLocations.getCitiesForState(null), isEmpty);
      expect(IndiaLocations.getCitiesForState('NonExistentState'), isEmpty);
    });
  });
}
