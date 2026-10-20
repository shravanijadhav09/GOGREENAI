import 'dart:io';
import 'dart:convert';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../features/ai/models/ai_models.dart';

export '../../features/ai/models/ai_models.dart';

/// Service that communicates with the GoGreenAI backend for all Gemini AI features:
///  - Plant identification from a photo
///  - Plant disease & pest diagnosis from a photo
///  - Plant disease recovery & treatment suggestions
///  - Structured care guides for specific plants
///  - Conversational plant assistant chat
///
/// Keeps all API keys safely on the backend. Never exposes credentials to the client.
class GeminiService {
  final ApiClient _api = ApiClient();
  static const Duration _aiTimeout = Duration(seconds: 45);

  /// Check whether Gemini is configured on the backend
  Future<bool> isAiConfigured() async {
    try {
      final res = await _api.get(ApiConstants.aiStatusEndpoint, timeout: const Duration(seconds: 10));
      final rawData = res['data'];
      if (rawData is Map<String, dynamic>) {
        return (rawData['isConfigured'] as bool?) ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// ── 1. Plant identification from camera/gallery image ──────────
  Future<PlantIdentificationResult> identifyPlant(
    File imageFile, {
    String language = 'en',
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final payload = {
      'imageBase64': base64Image,
      'mimeType': _resolveMimeType(imageFile.path),
      'language': language,
    };

    final res = await _api.post(
      ApiConstants.aiIdentifyEndpoint,
      payload,
      timeout: _aiTimeout,
    );
    final data = _extractMap(res['data']);
    return PlantIdentificationResult.fromJson(data);
  }

  /// ── 2. Plant disease & symptom diagnosis from image ────────────
  Future<PlantDiseaseDiagnosisResult> diagnosePlantDisease(
    File imageFile, {
    String description = '',
    String language = 'en',
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final payload = {
      'imageBase64': base64Image,
      'mimeType': _resolveMimeType(imageFile.path),
      'description': description,
      'language': language,
    };

    final res = await _api.post(
      ApiConstants.aiDiagnoseEndpoint,
      payload,
      timeout: _aiTimeout,
    );
    final data = _extractMap(res['data']);
    return PlantDiseaseDiagnosisResult.fromJson(data);
  }

  /// ── 3. Disease Treatment & recovery suggestions ────────────────
  Future<DiseaseTreatmentResult> getDiseaseTreatmentSuggestions({
    String plantName = '',
    String disease = '',
    String symptoms = '',
    String language = 'en',
  }) async {
    final payload = {
      if (plantName.isNotEmpty) 'plantName': plantName,
      if (disease.isNotEmpty) 'disease': disease,
      if (symptoms.isNotEmpty) 'symptoms': symptoms,
      'language': language,
    };

    final res = await _api.post(
      ApiConstants.aiTreatmentEndpoint,
      payload,
      timeout: _aiTimeout,
    );
    final data = _extractMap(res['data']);
    return DiseaseTreatmentResult.fromJson(data);
  }

  /// ── 4. Structured Care advice for a specific plant ─────────────
  Future<PlantCareAdviceResult> getPlantCareAdvice(
    String plantName, {
    String? userQuery,
    String language = 'en',
  }) async {
    final payload = {
      'plantName': plantName,
      if (userQuery != null && userQuery.trim().isNotEmpty)
        'userQuery': userQuery.trim(),
      'language': language,
    };

    final res = await _api.post(
      ApiConstants.aiCareAdviceEndpoint,
      payload,
      timeout: _aiTimeout,
    );
    final data = _extractMap(res['data']);
    return PlantCareAdviceResult.fromJson(data);
  }

  /// ── 5. Open-ended Q&A chat with plant assistant ────────────────
  Future<AiChatResult> chatWithPlantAssistant(
    String userMessage,
    List<Map<String, String>> history, {
    String language = 'en',
  }) async {
    final payload = {
      'message': userMessage,
      'history': history,
      'language': language,
    };

    final res = await _api.post(
      ApiConstants.aiChatEndpoint,
      payload,
      timeout: _aiTimeout,
    );
    final data = _extractMap(res['data']);
    return AiChatResult.fromJson(data);
  }

  Map<String, dynamic> _extractMap(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    if (rawData is List && rawData.isNotEmpty && rawData[0] is Map<String, dynamic>) {
      return rawData[0] as Map<String, dynamic>;
    }
    return {};
  }

  String _resolveMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
