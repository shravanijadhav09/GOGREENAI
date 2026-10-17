import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_constants.dart';

/// Service that wraps the Gemini SDK for all AI features:
///  - Plant identification from a photo
///  - Care advice for a named plant
///  - Open-ended plant Q&A chat
class GeminiService {
  late final GenerativeModel _visionModel;
  late final GenerativeModel _textModel;

  GeminiService() {
    const key = ApiConstants.geminiApiKey;
    _visionModel = GenerativeModel(model: ApiConstants.geminiModel, apiKey: key);
    _textModel = GenerativeModel(
      model: ApiConstants.geminiModel,
      apiKey: key,
      systemInstruction: Content.system(
        'You are GoGreen Assistant, a friendly expert in plant care, '
        'indoor gardening, and nursery plants. Answer concisely and helpfully. '
        'If the question is not about plants, politely redirect the user.',
      ),
    );
  }

  // ── Plant identification from camera image ─────────────────────
  Future<PlantIdentificationResult> identifyPlant(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final imagePart = DataPart('image/jpeg', bytes);

    final prompt = TextPart(
      'You are an expert botanist. Identify the plant in this image and respond '
      'in JSON only (no markdown) with the following fields:\n'
      '{"commonName":"...","scientificName":"...","confidence":"high|medium|low",'
      '"briefDescription":"...","careDifficulty":"EASY|MODERATE|EXPERT",'
      '"watering":"LOW|MEDIUM|HIGH","sunlight":"LOW|INDIRECT|DIRECT",'
      '"isIndoor":true|false,"isOutdoor":true|false,"isPetSafe":true|false}',
    );

    final response = await _visionModel.generateContent([
      Content.multi([imagePart, prompt]),
    ]);

    final text = response.text ?? '{}';
    final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final json = jsonDecode(cleaned) as Map<String, dynamic>;

    return PlantIdentificationResult.fromJson(json);
  }

  // ── Care advice for a specific plant ──────────────────────────
  Future<String> getPlantCareAdvice(String plantName, {String? userQuery}) async {
    final prompt = userQuery != null
        ? 'I have a plant called "$plantName". My question is: $userQuery. '
            'Give concise, actionable advice in 3-4 bullet points.'
        : 'Give me a concise care guide for "$plantName" covering: '
            'watering, sunlight, soil, common issues, and tips. '
            'Format as numbered steps, keep it practical.';

    final response = await _textModel.generateContent([Content.text(prompt)]);
    return response.text ?? 'Sorry, I could not generate care advice right now.';
  }

  // ── Open Q&A chat with plant assistant ────────────────────────
  Future<String> chatWithPlantAssistant(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    final chat = _textModel.startChat(
      history: history.map((msg) {
        return Content(
          msg['role'] == 'user' ? 'user' : 'model',
          [TextPart(msg['text'] ?? '')],
        );
      }).toList(),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 512,
      ),
    );

    final response = await chat.sendMessage(Content.text(userMessage));
    return response.text ?? 'Sorry, I could not respond right now.';
  }
}

class PlantIdentificationResult {
  final String commonName;
  final String scientificName;
  final String confidence;
  final String briefDescription;
  final String careDifficulty;
  final String watering;
  final String sunlight;
  final bool isIndoor;
  final bool isOutdoor;
  final bool isPetSafe;

  PlantIdentificationResult({
    required this.commonName,
    required this.scientificName,
    required this.confidence,
    required this.briefDescription,
    required this.careDifficulty,
    required this.watering,
    required this.sunlight,
    required this.isIndoor,
    required this.isOutdoor,
    required this.isPetSafe,
  });

  factory PlantIdentificationResult.fromJson(Map<String, dynamic> json) {
    return PlantIdentificationResult(
      commonName: json['commonName'] ?? 'Unknown plant',
      scientificName: json['scientificName'] ?? '',
      confidence: json['confidence'] ?? 'low',
      briefDescription: json['briefDescription'] ?? '',
      careDifficulty: json['careDifficulty'] ?? 'MODERATE',
      watering: json['watering'] ?? 'MEDIUM',
      sunlight: json['sunlight'] ?? 'INDIRECT',
      isIndoor: json['isIndoor'] ?? false,
      isOutdoor: json['isOutdoor'] ?? true,
      isPetSafe: json['isPetSafe'] ?? false,
    );
  }
}
