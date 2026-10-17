import 'dart:math';
import 'package:flutter/foundation.dart';
import '../features/plants/models/plant.dart';

class CartItem {
  final Plant plant;
  int quantity;

  CartItem({
    required this.plant,
    this.quantity = 1,
  });

  double get totalPrice => plant.price * quantity;

  CartItem copyWith({
    Plant? plant,
    int? quantity,
  }) {
    return CartItem(
      plant: plant ?? this.plant,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  int get totalCount => itemCount;
  int get uniqueItemCount => _items.length;

  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  String? get currentNurseryId =>
      _items.isEmpty ? null : _items.values.first.plant.nurseryId;

  String? get currentNurseryName =>
      _items.isEmpty ? null : _items.values.first.plant.nurseryName;

  bool isDifferentNursery(String nurseryId) {
    if (_items.isEmpty) return false;
    final current = currentNurseryId;
    return current != null && current.isNotEmpty && current != nurseryId;
  }

  /// Adds a plant to the cart.
  /// If the plant is from a different nursery than the current cart:
  /// - If [forceClear] is false, returns false so the UI can display a confirmation dialog.
  /// - If [forceClear] is true, clears the existing cart items and adds the new plant.
  bool addItem(Plant plant, {int quantity = 1, bool forceClear = false}) {
    if (plant.stock <= 0) return false;

    if (isDifferentNursery(plant.nurseryId)) {
      if (!forceClear) {
        return false;
      }
      _items.clear();
    }

    final availableStock = plant.stock;
    if (_items.containsKey(plant.id)) {
      final currentQty = _items[plant.id]!.quantity;
      final newQty = min(currentQty + quantity, availableStock);
      _items[plant.id]!.quantity = newQty;
    } else {
      final initialQty = min(quantity, availableStock);
      _items[plant.id] = CartItem(plant: plant, quantity: initialQty);
    }

    notifyListeners();
    return true;
  }

  /// Updates quantity of an item directly
  void updateQuantity(String plantId, int newQuantity) {
    if (!_items.containsKey(plantId)) return;

    if (newQuantity <= 0) {
      _items.remove(plantId);
    } else {
      final maxStock = _items[plantId]!.plant.stock;
      _items[plantId]!.quantity = min(newQuantity, maxStock);
    }
    notifyListeners();
  }

  /// Increments quantity by 1 if stock allows
  bool incrementQuantity(String plantId) {
    if (!_items.containsKey(plantId)) return false;
    final item = _items[plantId]!;
    if (item.quantity >= item.plant.stock) return false;

    item.quantity += 1;
    notifyListeners();
    return true;
  }

  /// Decrements quantity by 1 or removes if 0
  void decrementQuantity(String plantId) {
    if (!_items.containsKey(plantId)) return;
    final item = _items[plantId]!;
    if (item.quantity > 1) {
      item.quantity -= 1;
    } else {
      _items.remove(plantId);
    }
    notifyListeners();
  }

  /// Removes an item from the cart
  void removeItem(String plantId) {
    if (_items.remove(plantId) != null) {
      notifyListeners();
    }
  }

  /// Clears the entire cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  int getQuantity(String plantId) {
    return _items[plantId]?.quantity ?? 0;
  }
}
