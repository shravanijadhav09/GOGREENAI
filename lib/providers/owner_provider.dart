import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../features/nurseries/models/nursery.dart';
import '../features/plants/models/plant.dart';
import '../features/owner/models/gallery_image.dart';
import '../features/owner/models/nursery_order.dart';
import '../features/nurseries/models/feedback_model.dart';

enum OwnerLoadState { idle, loading, success, error }

class OwnerProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  Nursery? _nursery;
  List<Nursery> _myNurseries = [];
  Map<String, dynamic>? _dashboardStats;

  // ── Inventory State ──────────────────────────────────────────
  List<Plant> _inventory = [];
  bool _isInventoryLoading = false;
  String? _inventoryError;
  String? _plantImageError;
  String _inventorySearch = '';
  String _inventoryFilter = 'all'; // 'all', 'in_stock', 'out_of_stock', 'inactive'

  // ── Gallery State ────────────────────────────────────────────
  List<GalleryImage> _gallery = [];
  bool _isGalleryLoading = false;
  String? _galleryError;
  int _galleryUploadingCount = 0;
  int _galleryTotalToUpload = 0;

  // ── Orders State ─────────────────────────────────────────────
  List<NurseryOrder> _orders = [];
  bool _isOrdersLoading = false;
  String? _ordersError;
  String _orderFilter = 'all'; // 'all', 'PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED'

  // ── Feedback & Ratings State ─────────────────────────────────
  List<FeedbackModel> _feedbacks = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _isFeedbacksLoading = false;
  String? _feedbacksError;

  OwnerLoadState _state = OwnerLoadState.idle;
  String? _errorMessage;

  Nursery? get nursery => _nursery;
  List<Nursery> get myNurseries => _myNurseries;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  OwnerLoadState get state => _state;
  bool get isLoading => _state == OwnerLoadState.loading;
  String? get errorMessage => _errorMessage;

  bool get hasNursery => _nursery != null;

  // Inventory getters
  List<Plant> get inventory => _inventory;
  bool get isInventoryLoading => _isInventoryLoading;
  String? get inventoryError => _inventoryError;
  String? get plantImageError => _plantImageError;
  String get inventorySearch => _inventorySearch;
  String get inventoryFilter => _inventoryFilter;

  // Gallery getters
  List<GalleryImage> get gallery => _gallery;
  bool get isGalleryLoading => _isGalleryLoading;
  String? get galleryError => _galleryError;
  int get galleryUploadingCount => _galleryUploadingCount;
  int get galleryTotalToUpload => _galleryTotalToUpload;
  bool get isUploadingGallery => _galleryTotalToUpload > 0;

  // Orders getters
  List<NurseryOrder> get orders => _orders;
  bool get isOrdersLoading => _isOrdersLoading;
  String? get ordersError => _ordersError;
  String get orderFilter => _orderFilter;
  int get pendingOrdersCount => _orders.where((o) => o.status == OrderStatusEnum.pendingConfirmation).length;
  int get activeOrdersCount => _orders.where((o) => o.status != OrderStatusEnum.completed && o.status != OrderStatusEnum.cancelled && o.status != OrderStatusEnum.rejected).length;
  int get pendingPaymentVerificationCount => _orders.where((o) => o.paymentStatus == PaymentStatusEnum.submitted).length;

  List<NurseryOrder> get filteredOrders {
    if (_orderFilter == 'all') return _orders;
    if (_orderFilter == 'NEEDS_PAYMENT') {
      return _orders.where((o) => o.paymentStatus == PaymentStatusEnum.submitted).toList();
    }
    final target = OrderStatusEnum.fromString(_orderFilter);
    return _orders.where((o) => o.status == target).toList();
  }

  void setOrderFilter(String filter) {
    _orderFilter = filter;
    notifyListeners();
  }

  List<Plant> get filteredInventory {
    return _inventory.where((plant) {
      // 1. Status Filter
      if (_inventoryFilter == 'in_stock' && (plant.stock <= 0 || !plant.isActive)) {
        return false;
      }
      if (_inventoryFilter == 'out_of_stock' && (plant.stock > 0 || !plant.isActive)) {
        return false;
      }
      if (_inventoryFilter == 'inactive' && plant.isActive) {
        return false;
      }

      // 2. Search Query
      if (_inventorySearch.isNotEmpty) {
        final query = _inventorySearch.toLowerCase();
        final matchesName = plant.name.toLowerCase().contains(query);
        final matchesCategory = plant.category?.toLowerCase().contains(query) ?? false;
        final matchesTags = plant.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchesName && !matchesCategory && !matchesTags) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void setInventorySearch(String query) {
    _inventorySearch = query;
    notifyListeners();
  }

  void setInventoryFilter(String filter) {
    _inventoryFilter = filter;
    notifyListeners();
  }

  // Feedback getters
  List<FeedbackModel> get feedbacks => _feedbacks;
  double get averageRating => _averageRating;
  int get totalRatings => _totalRatings;
  bool get isFeedbacksLoading => _isFeedbacksLoading;
  String? get feedbacksError => _feedbacksError;

  void selectNursery(Nursery nursery) {
    _nursery = nursery;
    notifyListeners();
    fetchInventory();
    fetchGallery(refresh: true);
    fetchOwnerOrders(refresh: true);
    fetchFeedbacks();
    fetchOwnerDashboard(nurseryId: nursery.id);
  }

  /// Fetches the owner's nursery profile and dashboard metrics
  Future<void> fetchOwnerDashboard({String? nurseryId}) async {
    _state = OwnerLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetId = nurseryId ?? _nursery?.id;
      final query = targetId != null ? '?nurseryId=$targetId' : '';
      // 1. Fetch Nursery Profile(s)
      final mineRes = await _api.get('${ApiConstants.myNurseryEndpoint}$query');
      final rawData = mineRes['data'] as Map<String, dynamic>?;
      final rawNurseries = mineRes['nurseries'] as List<dynamic>?;

      if (rawNurseries != null) {
        _myNurseries = rawNurseries
            .map((j) => Nursery.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      if (rawData != null) {
        _nursery = Nursery.fromJson(rawData);
        if (_myNurseries.isEmpty) {
          _myNurseries = [_nursery!];
        }
      } else if (_myNurseries.isNotEmpty) {
        _nursery = _myNurseries.first;
      } else {
        _nursery = null;
        _myNurseries = [];
      }

      // 2. Fetch Dashboard Statistics
      final dashQuery = _nursery != null ? '?nurseryId=${_nursery!.id}' : '';
      final dashRes = await _api.get('${ApiConstants.myNurseryDashboardEndpoint}$dashQuery');
      _dashboardStats = dashRes['data'] as Map<String, dynamic>?;

      if (_dashboardStats != null) {
        if (_dashboardStats!['averageRating'] != null) {
          _averageRating = double.tryParse(_dashboardStats!['averageRating'].toString()) ?? 0.0;
        }
        if (_dashboardStats!['totalRatings'] != null) {
          _totalRatings = int.tryParse(_dashboardStats!['totalRatings'].toString()) ?? 0;
        }
      }

      _state = OwnerLoadState.success;
      _errorMessage = null;
    } on ApiException catch (e) {
      _state = OwnerLoadState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = OwnerLoadState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Register a brand new nursery for this owner
  Future<bool> registerNursery({
    required String name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? phone,
    String? logoUrl,
    double? latitude,
    double? longitude,
  }) async {
    _state = OwnerLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (state != null && state.trim().isNotEmpty) 'state': state.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (logoUrl != null && logoUrl.trim().isNotEmpty) 'logoUrl': logoUrl.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final res = await _api.post(ApiConstants.nurseriesEndpoint, body);
      final data = res['data'] as Map<String, dynamic>?;

      if (data != null) {
        _nursery = Nursery.fromJson(data);
        _myNurseries = [_nursery!];
      }

      // Refresh dashboard stats
      await fetchOwnerDashboard();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = OwnerLoadState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _state = OwnerLoadState.error;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing nursery profile
  Future<bool> updateNurseryProfile({
    required String nurseryId,
    String? name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? phone,
    String? logoUrl,
    double? latitude,
    double? longitude,
  }) async {
    _state = OwnerLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (description != null) 'description': description.trim(),
        if (address != null) 'address': address.trim(),
        if (city != null) 'city': city.trim(),
        if (state != null) 'state': state.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (logoUrl != null) 'logoUrl': logoUrl.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final res = await _api.patch('${ApiConstants.nurseriesEndpoint}/$nurseryId', body);
      final data = res['data'] as Map<String, dynamic>?;

      if (data != null) {
        _nursery = Nursery.fromJson(data);
        _myNurseries = [_nursery!];
      }

      _state = OwnerLoadState.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = OwnerLoadState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _state = OwnerLoadState.error;
      notifyListeners();
      return false;
    }
  }

  /// Upload nursery logo image to Cloudinary and return URL
  Future<String?> uploadLogo(File imageFile) async {
    try {
      final res = await _api.postMultipart(
        ApiConstants.uploadNurseryLogoEndpoint,
        imageFile,
        fieldName: 'image',
      );
      return res['url'] as String?;
    } catch (e) {
      _errorMessage = 'Logo upload failed: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── INVENTORY MANAGEMENT ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Fetch all plants belonging to the owner's nursery (including inactive & out-of-stock)
  Future<void> fetchInventory() async {
    _isInventoryLoading = true;
    _inventoryError = null;
    notifyListeners();

    try {
      final query = _nursery != null ? '?nurseryId=${_nursery!.id}' : '';
      final res = await _api.get('${ApiConstants.myPlantsEndpoint}$query');
      final rawList = res['data'] as List<dynamic>? ?? [];
      _inventory = rawList.map((j) => Plant.fromJson(j as Map<String, dynamic>)).toList();
      _isInventoryLoading = false;
      _inventoryError = null;
    } on ApiException catch (e) {
      _isInventoryLoading = false;
      _inventoryError = e.message;
    } catch (e) {
      _isInventoryLoading = false;
      _inventoryError = e.toString();
    }
    notifyListeners();
  }

  /// Upload plant image to Cloudinary
  Future<String?> uploadPlantImage(File imageFile) async {
    try {
      final res = await _api.postMultipart(
        ApiConstants.uploadPlantImageEndpoint,
        imageFile,
        fieldName: 'image',
      );
      _plantImageError = null;
      return res['url'] as String?;
    } catch (e) {
      _plantImageError = 'Plant image upload failed: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Add a new plant listing
  Future<bool> createPlant({
    required String name,
    required double price,
    required int stock,
    String? description,
    String? imageUrl,
    String? category,
    List<String> tags = const [],
    String? sunlight,
    String? watering,
    String? careDifficulty,
    bool? isIndoor,
    bool? isOutdoor,
    bool? isPetSafe,
    int? sizeCm,
  }) async {
    _isInventoryLoading = true;
    _inventoryError = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'price': price,
        'stock': stock,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (tags.isNotEmpty) 'tags': tags,
        if (sunlight != null && sunlight.isNotEmpty) 'sunlight': sunlight,
        if (watering != null && watering.isNotEmpty) 'watering': watering,
        if (careDifficulty != null && careDifficulty.isNotEmpty)
          'careDifficulty': careDifficulty,
        if (isIndoor != null) 'isIndoor': isIndoor,
        if (isOutdoor != null) 'isOutdoor': isOutdoor,
        if (isPetSafe != null) 'isPetSafe': isPetSafe,
        if (sizeCm != null) 'sizeCm': sizeCm,
      };

      await _api.post(ApiConstants.plantsEndpoint, body);
      await fetchInventory();
      await fetchOwnerDashboard(); // Update stats
      return true;
    } on ApiException catch (e) {
      _inventoryError = e.message;
      _isInventoryLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _inventoryError = e.toString();
      _isInventoryLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing plant listing
  Future<bool> updatePlant({
    required String plantId,
    String? name,
    double? price,
    int? stock,
    bool? isActive,
    String? description,
    String? imageUrl,
    String? category,
    List<String>? tags,
    String? sunlight,
    String? watering,
    String? careDifficulty,
    bool? isIndoor,
    bool? isOutdoor,
    bool? isPetSafe,
    int? sizeCm,
  }) async {
    _isInventoryLoading = true;
    _inventoryError = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (price != null) 'price': price,
        if (stock != null) 'stock': stock,
        if (isActive != null) 'isActive': isActive,
        if (description != null) 'description': description.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
        if (category != null) 'category': category.trim(),
        if (tags != null) 'tags': tags,
        if (sunlight != null) 'sunlight': sunlight.isEmpty ? null : sunlight,
        if (watering != null) 'watering': watering.isEmpty ? null : watering,
        if (careDifficulty != null)
          'careDifficulty': careDifficulty.isEmpty ? null : careDifficulty,
        if (isIndoor != null) 'isIndoor': isIndoor,
        if (isOutdoor != null) 'isOutdoor': isOutdoor,
        if (isPetSafe != null) 'isPetSafe': isPetSafe,
        if (sizeCm != null) 'sizeCm': sizeCm,
      };

      await _api.patch('${ApiConstants.plantsEndpoint}/$plantId', body);
      await fetchInventory();
      await fetchOwnerDashboard();
      return true;
    } on ApiException catch (e) {
      _inventoryError = e.message;
      _isInventoryLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _inventoryError = e.toString();
      _isInventoryLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Quick update stock quantity
  Future<bool> updateStock(String plantId, int newStock) async {
    try {
      await _api.patch('${ApiConstants.plantsEndpoint}/$plantId', {'stock': newStock});
      final index = _inventory.indexWhere((p) => p.id == plantId);
      if (index >= 0) {
        _inventory[index] = _inventory[index].copyWith(stock: newStock);
        notifyListeners();
      }
      await fetchOwnerDashboard();
      return true;
    } catch (e) {
      _inventoryError = 'Failed to update stock: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle active/inactive listing status
  Future<bool> togglePlantStatus(String plantId, bool newStatus) async {
    try {
      await _api.patch('${ApiConstants.plantsEndpoint}/$plantId', {'isActive': newStatus});
      final index = _inventory.indexWhere((p) => p.id == plantId);
      if (index >= 0) {
        _inventory[index] = _inventory[index].copyWith(isActive: newStatus);
        notifyListeners();
      }
      await fetchOwnerDashboard();
      return true;
    } catch (e) {
      _inventoryError = 'Failed to toggle status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deactivate / remove plant listing
  Future<bool> deletePlant(String plantId) async {
    try {
      await _api.delete('${ApiConstants.plantsEndpoint}/$plantId');
      _inventory.removeWhere((p) => p.id == plantId);
      notifyListeners();
      await fetchOwnerDashboard();
      return true;
    } catch (e) {
      _inventoryError = 'Failed to delete plant: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Gallery Methods ──────────────────────────────────────────

  /// Fetch all gallery images for the owner's nursery
  Future<void> fetchGallery({bool refresh = false}) async {
    if (!refresh && _gallery.isNotEmpty) return;
    _isGalleryLoading = true;
    _galleryError = null;
    notifyListeners();

    try {
      final query = _nursery != null ? '?nurseryId=${_nursery!.id}' : '';
      final res = await _api.get('${ApiConstants.nurseriesEndpoint}/mine/gallery$query');
      final list = (res['data'] as List<dynamic>?) ?? [];
      _gallery = list
          .map((item) => GalleryImage.fromJson(item as Map<String, dynamic>))
          .toList();
      _isGalleryLoading = false;
      notifyListeners();
    } catch (e) {
      _galleryError = 'Failed to load gallery: $e';
      _isGalleryLoading = false;
      notifyListeners();
    }
  }

  /// Upload a single photo to Cloudinary and register it in the nursery gallery
  Future<bool> uploadGalleryImage({
    required File file,
    String? caption,
    String? category,
  }) async {
    try {
      final uploadRes = await _api.postMultipart('/uploads/gallery-image', file);
      final url = uploadRes['url'] as String?;
      final publicId = uploadRes['publicId'] as String?;

      if (url == null || url.isEmpty) {
        throw Exception('Server did not return a valid image URL');
      }

      final res = await _api.post('${ApiConstants.nurseriesEndpoint}/mine/gallery', {
        'url': url,
        if (_nursery != null) 'nurseryId': _nursery!.id,
        if (publicId != null) 'publicId': publicId,
        if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      });

      final created = GalleryImage.fromJson(res['data'] as Map<String, dynamic>);
      _gallery.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _galleryError = 'Failed to upload image: $e';
      notifyListeners();
      return false;
    }
  }

  /// Batch upload multiple photos with progress tracking
  Future<int> uploadMultipleGalleryImages({
    required List<File> files,
    String? category,
  }) async {
    if (files.isEmpty) return 0;

    _galleryTotalToUpload = files.length;
    _galleryUploadingCount = 0;
    _galleryError = null;
    notifyListeners();

    int successCount = 0;

    for (final file in files) {
      try {
        final uploadRes = await _api.postMultipart('/uploads/gallery-image', file);
        final url = uploadRes['url'] as String?;
        final publicId = uploadRes['publicId'] as String?;

        if (url != null && url.isNotEmpty) {
          final res = await _api.post('${ApiConstants.nurseriesEndpoint}/mine/gallery', {
            'url': url,
            if (_nursery != null) 'nurseryId': _nursery!.id,
            if (publicId != null) 'publicId': publicId,
            if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
          });

          final created = GalleryImage.fromJson(res['data'] as Map<String, dynamic>);
          _gallery.insert(0, created);
          successCount++;
        }
      } catch (e) {
        // Continue uploading remaining photos even if one fails
      } finally {
        _galleryUploadingCount++;
        notifyListeners();
      }
    }

    _galleryTotalToUpload = 0;
    _galleryUploadingCount = 0;
    notifyListeners();
    return successCount;
  }

  /// Update an existing gallery image's caption or category
  Future<bool> updateGalleryImage({
    required String imageId,
    String? caption,
    String? category,
    int? sortOrder,
  }) async {
    try {
      final res = await _api.patch(
        '${ApiConstants.nurseriesEndpoint}/mine/gallery/$imageId',
        {
          if (caption != null) 'caption': caption.trim().isEmpty ? null : caption.trim(),
          if (category != null) 'category': category.trim().isEmpty ? null : category.trim(),
          if (sortOrder != null) 'sortOrder': sortOrder,
        },
      );

      final updated = GalleryImage.fromJson(res['data'] as Map<String, dynamic>);
      final idx = _gallery.indexWhere((img) => img.id == imageId);
      if (idx >= 0) {
        _gallery[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _galleryError = 'Failed to update photo: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a photo from the gallery
  Future<bool> deleteGalleryImage(String imageId) async {
    try {
      await _api.delete('${ApiConstants.nurseriesEndpoint}/mine/gallery/$imageId');
      _gallery.removeWhere((img) => img.id == imageId);
      notifyListeners();
      return true;
    } catch (e) {
      _galleryError = 'Failed to delete photo: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Order Management Methods ─────────────────────────────────

  /// Fetch all customer orders received by the nursery
  Future<void> fetchOwnerOrders({bool refresh = false}) async {
    if (!refresh && _orders.isNotEmpty) return;
    _isOrdersLoading = true;
    _ordersError = null;
    notifyListeners();

    try {
      final query = _nursery != null ? '?nurseryId=${_nursery!.id}' : '';
      final res = await _api.get('/orders/mine$query');
      final list = (res['data'] as List<dynamic>?) ?? [];
      _orders = list
          .map((item) => NurseryOrder.fromJson(item as Map<String, dynamic>))
          .toList();
      _isOrdersLoading = false;
      notifyListeners();
    } catch (e) {
      _ordersError = 'Failed to load orders: $e';
      _isOrdersLoading = false;
      notifyListeners();
    }
  }

  /// Fetch feedback & reviews received for this nursery
  Future<void> fetchFeedbacks() async {
    _isFeedbacksLoading = true;
    _feedbacksError = null;
    notifyListeners();

    try {
      final query = _nursery != null ? '?nurseryId=${_nursery!.id}' : '';
      final res = await _api.get('${ApiConstants.myNurseryFeedbacksEndpoint}$query');
      final list = (res['data'] as List<dynamic>?) ?? [];
      _feedbacks = list
          .map((item) => FeedbackModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (res['averageRating'] != null) {
        _averageRating = double.tryParse(res['averageRating'].toString()) ?? 0.0;
      }
      if (res['totalRatings'] != null) {
        _totalRatings = int.tryParse(res['totalRatings'].toString()) ?? _feedbacks.length;
      }
      _isFeedbacksLoading = false;
      notifyListeners();
    } catch (e) {
      _feedbacksError = 'Failed to load feedback: $e';
      _isFeedbacksLoading = false;
      notifyListeners();
    }
  }

  /// Update the lifecycle status of an order
  Future<bool> updateOrderStatus(String orderId, OrderStatusEnum newStatus, {String? note}) async {
    try {
      final res = await _api.patch(ApiConstants.orderStatusEndpoint(orderId), {
        'status': newStatus.apiValue,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });

      final updated = NurseryOrder.fromJson(res['data'] as Map<String, dynamic>);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx >= 0) {
        _orders[idx] = updated;
        notifyListeners();
      }

      // Also refresh dashboard stats (e.g. today's order count)
      fetchOwnerDashboard();
      return true;
    } catch (e) {
      _ordersError = 'Failed to update order status: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Payment Settings State & Methods ─────────────────────────
  bool _isPaymentSettingsLoading = false;
  String? _paymentSettingsError;

  bool get isPaymentSettingsLoading => _isPaymentSettingsLoading;
  String? get paymentSettingsError => _paymentSettingsError;

  /// Upload UPI QR Code image to Cloudinary
  Future<Map<String, String>?> uploadPaymentQr(File file) async {
    try {
      final uploadRes = await _api.postMultipart(ApiConstants.uploadPaymentQrEndpoint, file);
      final url = uploadRes['url'] as String?;
      final publicId = uploadRes['publicId'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Server did not return a valid QR image URL');
      }
      return {'url': url, if (publicId != null) 'publicId': publicId};
    } catch (e) {
      _paymentSettingsError = 'Failed to upload QR code: $e';
      notifyListeners();
      return null;
    }
  }

  /// Save or update nursery payment settings
  Future<bool> updatePaymentSettings({
    String? upiId,
    String? upiQrUrl,
    String? upiQrPublicId,
    bool? isUpiEnabled,
    bool? isPayAtPickupEnabled,
    bool? isCodEnabled,
  }) async {
    _isPaymentSettingsLoading = true;
    _paymentSettingsError = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        if (upiId != null) 'upiId': upiId.trim(),
        if (upiQrUrl != null) 'upiQrUrl': upiQrUrl,
        if (upiQrPublicId != null) 'upiQrPublicId': upiQrPublicId,
        if (isUpiEnabled != null) 'isUpiEnabled': isUpiEnabled,
        if (isPayAtPickupEnabled != null) 'isPayAtPickupEnabled': isPayAtPickupEnabled,
        if (isCodEnabled != null) 'isCodEnabled': isCodEnabled,
      };

      final res = await _api.patch(ApiConstants.paymentSettingsEndpoint, body);
      final updatedData = res['data'] as Map<String, dynamic>;

      if (_nursery != null) {
        _nursery = _nursery!.copyWith(
          upiId: updatedData['upiId'] as String?,
          upiQrUrl: updatedData['upiQrUrl'] as String?,
          upiQrPublicId: updatedData['upiQrPublicId'] as String?,
          isUpiEnabled: updatedData['isUpiEnabled'] as bool?,
          isPayAtPickupEnabled: updatedData['isPayAtPickupEnabled'] as bool?,
          isCodEnabled: updatedData['isCodEnabled'] as bool?,
        );
      }

      _isPaymentSettingsLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _paymentSettingsError = 'Failed to update payment settings: $e';
      _isPaymentSettingsLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Manually confirm or update payment verification status of an order
  Future<bool> confirmOrderPayment(
    String orderId,
    PaymentStatusEnum newPaymentStatus, {
    String? note,
  }) async {
    try {
      final res = await _api.patch(
        ApiConstants.orderPaymentStatusEndpoint(orderId),
        {
          'paymentStatus': newPaymentStatus.apiValue,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );

      final updated = NurseryOrder.fromJson(res['data'] as Map<String, dynamic>);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx >= 0) {
        _orders[idx] = updated;
        notifyListeners();
      }

      fetchOwnerDashboard();
      return true;
    } catch (e) {
      _ordersError = 'Failed to update payment status: $e';
      notifyListeners();
      return false;
    }
  }
}
