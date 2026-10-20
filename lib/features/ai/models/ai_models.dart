// lib/features/ai/models/ai_models.dart
// Strongly-typed models for all GoGreenAI Gemini responses.

class PlantIdentificationResult {
  final String plantName;
  final String commonName;
  final String confidence;
  final List<String> characteristics;
  final List<String> suggestedNextSteps;
  final PlantCareSummary? careSummary;

  PlantIdentificationResult({
    required this.plantName,
    required this.commonName,
    required this.confidence,
    required this.characteristics,
    required this.suggestedNextSteps,
    this.careSummary,
  });

  factory PlantIdentificationResult.fromJson(Map<String, dynamic> json) {
    return PlantIdentificationResult(
      plantName: json['plantName'] ?? 'Unidentified Plant',
      commonName: json['commonName'] ?? '',
      confidence: json['confidence'] ?? 'Visual identification based on available characteristics.',
      characteristics: (json['characteristics'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      suggestedNextSteps: (json['suggestedNextSteps'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      careSummary: json['careSummary'] is Map<String, dynamic>
          ? PlantCareSummary.fromJson(json['careSummary'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlantCareSummary {
  final String watering;
  final String sunlight;
  final String difficulty;

  PlantCareSummary({
    required this.watering,
    required this.sunlight,
    required this.difficulty,
  });

  factory PlantCareSummary.fromJson(Map<String, dynamic> json) {
    return PlantCareSummary(
      watering: json['watering'] ?? 'MEDIUM',
      sunlight: json['sunlight'] ?? 'INDIRECT',
      difficulty: json['difficulty'] ?? 'MODERATE',
    );
  }
}

class PlantDiseaseDiagnosisResult {
  final String plantName;
  final List<String> observedSymptoms;
  final String possibleDisease;
  final String severity; // Low, Moderate, High
  final List<String> recommendedTreatments;
  final List<String> preventionMeasures;
  final String expertConsultationGuidance;
  final String isEstimateNotice;

  PlantDiseaseDiagnosisResult({
    required this.plantName,
    required this.observedSymptoms,
    required this.possibleDisease,
    required this.severity,
    required this.recommendedTreatments,
    required this.preventionMeasures,
    required this.expertConsultationGuidance,
    required this.isEstimateNotice,
  });

  factory PlantDiseaseDiagnosisResult.fromJson(Map<String, dynamic> json) {
    return PlantDiseaseDiagnosisResult(
      plantName: json['plantName'] ?? 'Foliage / Plant Sample',
      observedSymptoms: (json['observedSymptoms'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      possibleDisease: json['possibleDisease'] ?? 'Foliar Stress / Unspecified Disease',
      severity: json['severity'] ?? 'Moderate',
      recommendedTreatments: (json['recommendedTreatments'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      preventionMeasures: (json['preventionMeasures'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      expertConsultationGuidance: json['expertConsultationGuidance'] ??
          'Consult a local horticulturist if symptoms spread rapidly or foliage decays.',
      isEstimateNotice: json['isEstimateNotice'] ??
          'This diagnosis is an AI-assisted visual estimate. Consult a local horticulturist or agricultural extension officer for laboratory confirmation.',
    );
  }
}

class PlantCareAdviceResult {
  final String plantName;
  final String shortAnswer;
  final String wateringGuidance;
  final String lightRequirements;
  final String soilConditions;
  final List<String> careSteps;
  final List<String> warnings;

  PlantCareAdviceResult({
    required this.plantName,
    required this.shortAnswer,
    required this.wateringGuidance,
    required this.lightRequirements,
    required this.soilConditions,
    required this.careSteps,
    required this.warnings,
  });

  factory PlantCareAdviceResult.fromJson(Map<String, dynamic> json) {
    return PlantCareAdviceResult(
      plantName: json['plantName'] ?? 'Plant Care',
      shortAnswer: json['shortAnswer'] ?? 'Here are the recommended growing conditions.',
      wateringGuidance: json['wateringGuidance'] ?? 'Water thoroughly when the top 2 inches of soil feel dry.',
      lightRequirements: json['lightRequirements'] ?? 'Bright, indirect sunlight is optimal.',
      soilConditions: json['soilConditions'] ?? 'Well-draining, nutrient-rich potting mix with perlite.',
      careSteps: (json['careSteps'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class AiChatResult {
  final String reply;
  final List<String> careTips;

  AiChatResult({
    required this.reply,
    required this.careTips,
  });

  factory AiChatResult.fromJson(Map<String, dynamic> json) {
    return AiChatResult(
      reply: json['reply'] ?? 'I could not process the query right now.',
      careTips: (json['careTips'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class DiseaseTreatmentResult {
  final String plantName;
  final String condition;
  final String urgency;
  final List<String> immediateActions;
  final List<String> organicTreatments;
  final List<String> environmentalAdjustments;
  final List<String> preventionMeasures;
  final List<String> warnings;

  DiseaseTreatmentResult({
    required this.plantName,
    required this.condition,
    required this.urgency,
    required this.immediateActions,
    required this.organicTreatments,
    required this.environmentalAdjustments,
    required this.preventionMeasures,
    required this.warnings,
  });

  factory DiseaseTreatmentResult.fromJson(Map<String, dynamic> json) {
    return DiseaseTreatmentResult(
      plantName: json['plantName'] ?? '',
      condition: json['condition'] ?? '',
      urgency: json['urgency'] ?? 'Routine observation',
      immediateActions: (json['immediateActions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      organicTreatments: (json['organicTreatments'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      environmentalAdjustments: (json['environmentalAdjustments'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      preventionMeasures: (json['preventionMeasures'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

