import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Optional override via --dart-define=API_BASE_URL=http://...
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String? _resolvedBaseUrl;

  static void setBaseUrl(String url) {
    _resolvedBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Candidate URLs in priority order for auto-detection
  static List<String> get candidateUrls {
    if (_envBaseUrl.isNotEmpty) return [_envBaseUrl];
    if (kIsWeb) return ['http://localhost:5000/api'];
    if (defaultTargetPlatform == TargetPlatform.android) {
      return [
        'http://localhost:5000/api', // Physical Android device via USB adb reverse
        'http://10.0.2.2:5000/api',   // Android Emulator
        'http://172.16.57.0:5000/api', // LAN Wi-Fi
      ];
    }
    return ['http://localhost:5000/api'];
  }

  /// Base URL for the GoGreen-AI Express backend
  /// Supports physical USB connection (adb reverse tcp:5000 tcp:5000), emulator (10.0.2.2), and web.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    if (kIsWeb) return 'http://localhost:5000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Default to localhost:5000/api if adb reverse or emulator 10.0.2.2 is probed
      return 'http://localhost:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  /// Gemini API Key configuration
  /// Can be supplied at build/run time via:
  /// flutter run --dart-define=GEMINI_API_KEY=your_key_here
  /// Or replace the fallback value below with your Google AI Studio key.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Gemini Model Name
  static const String geminiModel = 'gemini-1.5-flash';

  // ── Auth Endpoints ──────────────────────────────────────────
  static const String loginEndpoint = '/auth/login';
  static const String registerCustomerEndpoint = '/auth/register';
  static const String registerOwnerEndpoint = '/auth/register-owner';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';

  // ── Core Domain Endpoints ───────────────────────────────────
  static const String plantsEndpoint = '/plants';
  static const String myPlantsEndpoint = '/plants/mine';
  static const String nurseriesEndpoint = '/nurseries';
  static const String myNurseryEndpoint = '/nurseries/mine';
  static const String myNurseryDashboardEndpoint = '/nurseries/mine/dashboard';
  static const String recommendationsEndpoint = '/recommendations';
  static const String healthEndpoint = '/health';

  // ── Upload Endpoints ─────────────────────────────────────────
  static const String uploadPlantImageEndpoint = '/uploads/plant-image';
  static const String uploadNurseryLogoEndpoint = '/uploads/nursery-logo';
  static const String uploadGalleryImageEndpoint = '/uploads/gallery-image';
  static const String uploadPaymentQrEndpoint = '/uploads/payment-qr';
  static const String uploadPaymentProofEndpoint = '/uploads/payment-proof';

  // ── Orders & Payment Endpoints ──────────────────────────────
  static const String ordersEndpoint = '/orders';
  static const String myOrdersEndpoint = '/orders/mine';
  static const String customerOrdersEndpoint = '/orders/my-orders';
  static const String paymentSettingsEndpoint = '/nurseries/mine/payment-settings';

  static String orderStatusEndpoint(String orderId) => '/orders/$orderId/status';
  static String orderPaymentStatusEndpoint(String orderId) => '/orders/$orderId/payment-status';
}
