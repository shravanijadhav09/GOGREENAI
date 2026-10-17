import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

/// Generic HTTP client wrapper for the GoGreen-AI backend REST API.
/// Supports transparent Bearer token authentication and JWT refresh rotation.
class ApiClient {
  final SecureStorageService _storage = SecureStorageService();
  static const Duration _timeout = Duration(seconds: 12);

  String get _baseUrl => ApiConstants.baseUrl;

  Future<Map<String, String>> _headers([String? explicitToken]) async {
    final token = explicitToken ?? await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Connection': 'close',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static bool _hasProbed = false;

  Future<bool> _probeCandidates() async {
    for (final candidate in ApiConstants.candidateUrls) {
      try {
        final res = await http
            .get(Uri.parse('$candidate${ApiConstants.healthEndpoint}'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          ApiConstants.setBaseUrl(candidate);
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<Map<String, dynamic>> get(String path, {String? token, bool isRetry = false}) async {
    try {
      final headers = await _headers(token);
      http.Response response = await http
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 401 && token == null) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryHeaders = await _headers();
          response = await http
              .get(
                Uri.parse('$_baseUrl$path'),
                headers: retryHeaders,
              )
              .timeout(_timeout);
        }
      }

      return _parse(response);
    } on TimeoutException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return get(path, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection timed out. Ensure the backend server is running and USB port forwarding is enabled.',
        408,
      );
    } on SocketException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return get(path, token: token, isRetry: true);
      }
      throw ApiException(
        'Unable to reach backend at $_baseUrl. Check network connection or USB cable.',
        503,
      );
    } on http.ClientException {
      if (!isRetry) {
        return get(path, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection interrupted. Please verify backend server is reachable.',
        503,
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
    bool isRetry = false,
  }) async {
    try {
      final headers = await _headers(token);
      http.Response response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 401 &&
          token == null &&
          path != ApiConstants.loginEndpoint &&
          path != ApiConstants.refreshTokenEndpoint) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryHeaders = await _headers();
          response = await http
              .post(
                Uri.parse('$_baseUrl$path'),
                headers: retryHeaders,
                body: jsonEncode(body),
              )
              .timeout(_timeout);
        }
      }

      return _parse(response);
    } on TimeoutException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return post(path, body, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection timed out. Ensure the backend server is running and USB port forwarding is enabled.',
        408,
      );
    } on SocketException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return post(path, body, token: token, isRetry: true);
      }
      throw ApiException(
        'Unable to reach backend at $_baseUrl. Check network connection or USB cable.',
        503,
      );
    } on http.ClientException {
      if (!isRetry) {
        return post(path, body, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection interrupted. Please verify backend server is reachable.',
        503,
      );
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
    bool isRetry = false,
  }) async {
    try {
      final headers = await _headers(token);
      http.Response response = await http
          .patch(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 401 && token == null) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryHeaders = await _headers();
          response = await http
              .patch(
                Uri.parse('$_baseUrl$path'),
                headers: retryHeaders,
                body: jsonEncode(body),
              )
              .timeout(_timeout);
        }
      }

      return _parse(response);
    } on TimeoutException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return patch(path, body, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection timed out. Ensure the backend server is running and USB port forwarding is enabled.',
        408,
      );
    } on SocketException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return patch(path, body, token: token, isRetry: true);
      }
      throw ApiException(
        'Unable to reach backend at $_baseUrl. Check network connection or USB cable.',
        503,
      );
    } on http.ClientException {
      if (!isRetry) {
        return patch(path, body, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection interrupted. Please verify backend server is reachable.',
        503,
      );
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
    bool isRetry = false,
  }) async {
    try {
      final headers = await _headers(token);
      http.Response response = await http
          .delete(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 401 && token == null) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryHeaders = await _headers();
          response = await http
              .delete(
                Uri.parse('$_baseUrl$path'),
                headers: retryHeaders,
              )
              .timeout(_timeout);
        }
      }

      return _parse(response);
    } on TimeoutException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return delete(path, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection timed out. Ensure the backend server is running and USB port forwarding is enabled.',
        408,
      );
    } on SocketException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return delete(path, token: token, isRetry: true);
      }
      throw ApiException(
        'Unable to reach backend at $_baseUrl. Check network connection or USB cable.',
        503,
      );
    } on http.ClientException {
      if (!isRetry) {
        return delete(path, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection interrupted. Please verify backend server is reachable.',
        503,
      );
    }
  }

  /// Uploads a single file using multipart/form-data with Bearer token authentication
  Future<Map<String, dynamic>> postMultipart(
    String path,
    File file, {
    String fieldName = 'image',
    String? token,
    bool isRetry = false,
  }) async {
    try {
      final tokenValue = token ?? await _storage.getAccessToken();
      final uri = Uri.parse('$_baseUrl$path');
      final request = http.MultipartRequest('POST', uri);

      if (tokenValue != null && tokenValue.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $tokenValue';
      }
      request.headers['Accept'] = 'application/json';
      request.headers['Connection'] = 'close';

      final filename = file.path.split(RegExp(r'[\\/]')).last;
      final lower = filename.toLowerCase();
      MediaType contentType;
      if (lower.endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (lower.endsWith('.webp')) {
        contentType = MediaType('image', 'webp');
      } else {
        contentType = MediaType('image', 'jpeg');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: filename,
          contentType: contentType,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 35));
      http.Response response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && token == null) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return await postMultipart(path, file, fieldName: fieldName, isRetry: true);
        }
      }

      return _parse(response);
    } on TimeoutException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return await postMultipart(path, file, fieldName: fieldName, token: token, isRetry: true);
      }
      throw ApiException(
        'Upload timed out. Ensure the backend server is running.',
        408,
      );
    } on SocketException {
      if (!isRetry && !_hasProbed) {
        _hasProbed = true;
        final switched = await _probeCandidates();
        if (switched) return postMultipart(path, file, fieldName: fieldName, token: token, isRetry: true);
      }
      throw ApiException(
        'Unable to reach backend at $_baseUrl.',
        503,
      );
    } on http.ClientException {
      if (!isRetry) {
        return postMultipart(path, file, fieldName: fieldName, token: token, isRetry: true);
      }
      throw ApiException(
        'Connection interrupted during upload. Please verify backend server is reachable.',
        503,
      );
    }
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl${ApiConstants.refreshTokenEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newAccess != null) {
          await _storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh ?? refreshToken,
          );
          return true;
        }
      }
    } catch (_) {
      // Network failure or invalid refresh token
    }

    return false;
  }

  Map<String, dynamic> _parse(http.Response response) {
    Map<String, dynamic> decoded = {};
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Server returned invalid response (${response.statusCode})',
        response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      final errorMsg = decoded['message'] ?? decoded['error'] ?? 'Request failed';
      throw ApiException(errorMsg.toString(), response.statusCode);
    }
    return decoded;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
