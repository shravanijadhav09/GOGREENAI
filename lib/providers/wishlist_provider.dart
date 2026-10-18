import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/plants/models/plant.dart';

class WishlistProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();

  List<Plant> _items = [];
  bool _isLoading = false;

  List<Plant> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;

  bool isWishlisted(String plantId) {
    return _items.any((p) => p.id == plantId);
  }

  bool contains(String plantId) => isWishlisted(plantId);
  Future<bool> toggle(Plant plant) => toggleWishlist(plant);
  Future<void> add(Plant plant) => addToWishlist(plant);
  Future<void> clear() => clearWishlist();

  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      final raw = await _storage.getWishlistRaw();
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _items = list
            .map((item) => Plant.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleWishlist(Plant plant) async {
    final idx = _items.indexWhere((p) => p.id == plant.id);
    bool added;
    if (idx != -1) {
      _items.removeAt(idx);
      added = false;
    } else {
      _items.insert(0, plant);
      added = true;
    }
    notifyListeners();
    await _save();
    return added;
  }

  Future<void> addToWishlist(Plant plant) async {
    if (!isWishlisted(plant.id)) {
      _items.insert(0, plant);
      notifyListeners();
      await _save();
    }
  }

  Future<void> removeFromWishlist(String plantId) async {
    final beforeCount = _items.length;
    _items.removeWhere((p) => p.id == plantId);
    if (_items.length != beforeCount) {
      notifyListeners();
      await _save();
    }
  }

  Future<void> clearWishlist() async {
    _items.clear();
    notifyListeners();
    await _save();
  }

  /// Syncs real-time plant stock, price, and availability from backend catalogue
  void syncWithPlants(List<Plant> plants) {
    if (_items.isEmpty) return;
    bool changed = false;

    for (int i = 0; i < _items.length; i++) {
      final matching = plants.where((p) => p.id == _items[i].id).firstOrNull;
      if (matching != null) {
        if (_items[i].stock != matching.stock || _items[i].price != matching.price) {
          _items[i] = matching;
          changed = true;
        }
      }
    }

    if (changed) {
      notifyListeners();
      _save();
    }
  }

  Future<void> _save() async {
    try {
      final jsonList = _items.map((p) => p.toJson()).toList();
      await _storage.saveWishlistRaw(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving wishlist: $e');
    }
  }
}
