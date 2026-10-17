import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;
  String? _manualCity;
  LocationPermission _permission = LocationPermission.denied;
  bool _serviceEnabled = false;

  Position? get currentPosition => _currentPosition;
  double? get userLatitude => _currentPosition?.latitude;
  double? get userLongitude => _currentPosition?.longitude;
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;
  bool get hasLocation => _currentPosition != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get manualCity => _manualCity;
  LocationPermission get permission => _permission;
  bool get serviceEnabled => _serviceEnabled;

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Requests location permissions only on user action and retrieves current position.
  /// Handles service disabled, permissions denied, and permission denied forever gracefully.
  Future<bool> requestUserLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        _errorMessage = 'Location services are disabled on your device. Please turn on GPS.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _permission = await Geolocator.checkPermission();
      if (_permission == LocationPermission.denied) {
        _permission = await Geolocator.requestPermission();
        if (_permission == LocationPermission.denied) {
          _errorMessage = 'Location permission was denied. You can filter nurseries by city instead.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (_permission == LocationPermission.deniedForever) {
        _errorMessage =
            'Location permission is permanently denied. You can select your city or enable it in App Settings.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Permissions granted, fetch position with 8 second timeout
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not acquire GPS position ($e). Using manual list.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Allows setting a manual city filter fallback when GPS is not used or denied
  void setManualCity(String? city) {
    if (city == null || city.trim().isEmpty || city.trim().toLowerCase() == 'all') {
      _manualCity = null;
    } else {
      _manualCity = city.trim();
    }
    notifyListeners();
  }

  /// Clears GPS location
  void clearLocation() {
    _currentPosition = null;
    _errorMessage = null;
    notifyListeners();
  }
}
