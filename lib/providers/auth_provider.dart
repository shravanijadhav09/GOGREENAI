import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/auth/models/user_model.dart';

enum AuthStatus {
  uninitialized,
  authenticating,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;
  bool get isAuthenticating => _status == AuthStatus.authenticating;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ── Session Restoration ─────────────────────────────────────────
  Future<void> tryRestoreSession() async {
    final refreshToken = await _storage.getRefreshToken();
    final accessToken = await _storage.getAccessToken();

    if (refreshToken == null && accessToken == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final res = await _api.get(ApiConstants.meEndpoint);
      if (res['success'] == true && res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        await _storage.saveUser(_currentUser!);
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Access token might be expired; ApiClient tries refresh automatically.
      // If network is offline, check local cached user below.
    }

    // If offline or network error occurred, restore the cached user session
    final cachedUser = await _storage.getUser();
    if (cachedUser != null) {
      _currentUser = cachedUser;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    // If backend cannot verify session and no cached user, wipe storage and log out
    await _storage.clearAuth();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Login ───────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiConstants.loginEndpoint,
        {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final accessToken = res['accessToken'] as String?;
      final refreshToken = res['refreshToken'] as String?;
      final userData = res['user'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        throw ApiException('Invalid server response during login.', 500);
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      _currentUser = UserModel.fromJson(userData);
      await _storage.saveUser(_currentUser!);

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Customer Registration ───────────────────────────────────────
  Future<bool> registerCustomer({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
      };
      if (firstName != null && firstName.trim().isNotEmpty) {
        body['firstName'] = firstName.trim();
      }
      if (lastName != null && lastName.trim().isNotEmpty) {
        body['lastName'] = lastName.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        body['phone'] = phone.trim();
      }

      final res = await _api.post(ApiConstants.registerCustomerEndpoint, body);

      final accessToken = res['accessToken'] as String?;
      final refreshToken = res['refreshToken'] as String?;
      final userData = res['user'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        throw ApiException('Registration succeeded but received invalid token.', 500);
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      _currentUser = UserModel.fromJson(userData);
      await _storage.saveUser(_currentUser!);

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Nursery Owner Registration ──────────────────────────────────
  Future<bool> registerOwner({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
      };
      if (firstName != null && firstName.trim().isNotEmpty) {
        body['firstName'] = firstName.trim();
      }
      if (lastName != null && lastName.trim().isNotEmpty) {
        body['lastName'] = lastName.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        body['phone'] = phone.trim();
      }

      final res = await _api.post(ApiConstants.registerOwnerEndpoint, body);

      final accessToken = res['accessToken'] as String?;
      final refreshToken = res['refreshToken'] as String?;
      final userData = res['user'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        throw ApiException('Owner registration succeeded but received invalid token.', 500);
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      _currentUser = UserModel.fromJson(userData);
      await _storage.saveUser(_currentUser!);

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Owner registration failed: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Update Profile ──────────────────────────────────────────────
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        if (firstName != null) 'firstName': firstName.trim().isEmpty ? null : firstName.trim(),
        if (lastName != null) 'lastName': lastName.trim().isEmpty ? null : lastName.trim(),
        if (phone != null) 'phone': phone.trim().isEmpty ? null : phone.trim(),
        if (avatarUrl != null) 'avatarUrl': avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
      };

      final res = await _api.patch(ApiConstants.meEndpoint, body);
      if (res['success'] == true && res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        await _storage.saveUser(_currentUser!);
        notifyListeners();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Logout ──────────────────────────────────────────────────────
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _api.post(ApiConstants.logoutEndpoint, {'refreshToken': refreshToken});
      } catch (_) {
        // Silently ignore server errors on logout
      }
    }

    await _storage.clearAuth();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}
