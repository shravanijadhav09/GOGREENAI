import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../features/plants/models/plant.dart';
import '../features/nurseries/models/nursery.dart';

enum LoadState { idle, loading, loaded, error }

class AppProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // ── Plants state ──────────────────────────────────────────────
  List<Plant> _plants = [];
  LoadState _plantsState = LoadState.idle;
  String? _plantsError;

  List<Plant> get plants => _plants;
  LoadState get plantsState => _plantsState;
  String? get plantsError => _plantsError;

  // ── Nurseries state ───────────────────────────────────────────
  List<Nursery> _nurseries = [];
  LoadState _nurseriesState = LoadState.idle;
  String? _nurseriesError;

  List<Nursery> get nurseries => _nurseries;
  LoadState get nurseriesState => _nurseriesState;
  String? get nurseriesError => _nurseriesError;

  // ── Plant search & filtering ──────────────────────────────────
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedPlacement; // 'Indoor', 'Outdoor', null
  double? _maxPrice;
  bool _onlyInStock = false;
  bool _onlyMedicinal = false;

  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedPlacement => _selectedPlacement;
  double? get maxPrice => _maxPrice;
  bool get onlyInStock => _onlyInStock;
  bool get onlyMedicinal => _onlyMedicinal;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _selectedPlacement != null ||
      _maxPrice != null ||
      _onlyInStock ||
      _onlyMedicinal;

  List<Plant> get filteredPlants {
    return _plants.where((p) {
      // 1. Text search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = p.name.toLowerCase().contains(q);
        final matchesCat = p.category?.toLowerCase().contains(q) ?? false;
        final matchesNursery = p.nurseryName?.toLowerCase().contains(q) ?? false;
        final matchesTags = p.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchesName && !matchesCat && !matchesNursery && !matchesTags) {
          return false;
        }
      }

      // 2. Category filter
      if (_selectedCategory != null && _selectedCategory != 'All') {
        final cat = (p.category ?? '').toLowerCase();
        final selected = _selectedCategory!.toLowerCase();
        if (!cat.contains(selected) && !p.tags.any((t) => t.toLowerCase().contains(selected))) {
          return false;
        }
      }

      // 3. Placement filter (Indoor / Outdoor)
      if (_selectedPlacement != null && _selectedPlacement != 'All') {
        if (_selectedPlacement == 'Indoor' && p.isIndoor != true) return false;
        if (_selectedPlacement == 'Outdoor' && p.isOutdoor != true) return false;
      }

      // 4. Price ceiling
      if (_maxPrice != null && p.price > _maxPrice!) {
        return false;
      }

      // 5. In-stock only
      if (_onlyInStock && !p.inStock) {
        return false;
      }

      // 6. Medicinal use
      if (_onlyMedicinal && !p.isMedicinal) {
        return false;
      }

      return true;
    }).toList();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategoryFilter(String? cat) {
    if (cat == 'All') {
      _selectedCategory = null;
    } else {
      _selectedCategory = cat;
    }
    notifyListeners();
  }

  void setSelectedCategory(String? cat) => setCategoryFilter(cat);

  void setPlacementFilter(String? placement) {
    if (placement == 'All') {
      _selectedPlacement = null;
    } else {
      _selectedPlacement = placement;
    }
    notifyListeners();
  }

  void setSelectedPlacement(String? placement) => setPlacementFilter(placement);

  void setMaxPrice(double? price) {
    _maxPrice = price;
    notifyListeners();
  }

  void setOnlyInStock(bool inStock) {
    _onlyInStock = inStock;
    notifyListeners();
  }

  void setOnlyMedicinal(bool medicinal) {
    _onlyMedicinal = medicinal;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedPlacement = null;
    _maxPrice = null;
    _onlyInStock = false;
    _onlyMedicinal = false;
    notifyListeners();
  }

  // ── Fetch all plants ──────────────────────────────────────────
  Future<void> fetchPlants() async {
    if (_plantsState == LoadState.loading) return;
    _plantsState = LoadState.loading;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.plantsEndpoint);
      final data = res['data'] as List<dynamic>;
      _plants = data.map((j) => Plant.fromJson(j as Map<String, dynamic>)).toList();
      _plantsState = LoadState.loaded;
      _plantsError = null;
    } catch (e) {
      _plantsState = LoadState.error;
      _plantsError = e.toString();
    }
    notifyListeners();
  }

  // ── Fetch plants for a specific nursery ────────────────────────
  Future<List<Plant>> fetchPlantsForNursery(String nurseryId) async {
    try {
      final res = await _api.get('${ApiConstants.plantsEndpoint}?nurseryId=$nurseryId');
      final data = res['data'] as List<dynamic>;
      return data.map((j) => Plant.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }


  // ── Fetch all nurseries ───────────────────────────────────────
  Future<void> fetchNurseries() async {
    if (_nurseriesState == LoadState.loading) return;
    _nurseriesState = LoadState.loading;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.nurseriesEndpoint);
      final data = res['data'] as List<dynamic>;
      _nurseries =
          data.map((j) => Nursery.fromJson(j as Map<String, dynamic>)).toList();
      _nurseriesState = LoadState.loaded;
      _nurseriesError = null;
    } catch (e) {
      _nurseriesState = LoadState.error;
      _nurseriesError = e.toString();
    }
    notifyListeners();
  }

  // ── Recommendations ───────────────────────────────────────────
  List<dynamic> _recommendations = [];
  LoadState _recState = LoadState.idle;

  List<dynamic> get recommendations => _recommendations;
  LoadState get recState => _recState;

  Future<void> fetchRecommendations({
    String? placement,
    String? sunlight,
    String? watering,
    int topN = 10,
  }) async {
    _recState = LoadState.loading;
    notifyListeners();

    try {
      final body = <String, dynamic>{'topN': topN};
      if (placement != null) body['placement'] = placement;
      if (sunlight != null) body['sunlight'] = sunlight;
      if (watering != null) body['watering'] = watering;

      final res = await _api.post(ApiConstants.recommendationsEndpoint, body);
      _recommendations = res['data'] as List<dynamic>;
      _recState = LoadState.loaded;
    } catch (e) {
      _recState = LoadState.error;
    }
    notifyListeners();
  }
}
