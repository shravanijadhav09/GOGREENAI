class Plant {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? category;
  final double price;
  final int stock;
  final bool isActive;
  final String? sunlight;
  final String? watering;
  final String? careDifficulty;
  final bool? isIndoor;
  final bool? isOutdoor;
  final bool? isPetSafe;
  final int? sizeCm;
  final List<String> climate;
  final List<String> tags;
  final String nurseryId;
  final String? nurseryName;
  final String? nurseryCity;
  final String? nurseryState;
  final String? nurseryAddress;
  final String? nurseryLogoUrl;

  Plant({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.category,
    required this.price,
    required this.stock,
    this.isActive = true,
    this.sunlight,
    this.watering,
    this.careDifficulty,
    this.isIndoor,
    this.isOutdoor,
    this.isPetSafe,
    this.sizeCm,
    this.climate = const [],
    this.tags = const [],
    required this.nurseryId,
    this.nurseryName,
    this.nurseryCity,
    this.nurseryState,
    this.nurseryAddress,
    this.nurseryLogoUrl,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    final nurseryMap = json['nursery'] as Map<String, dynamic>?;
    return Plant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String?,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stock: (json['stock'] as int?) ?? 0,
      isActive: (json['isActive'] as bool?) ?? true,
      sunlight: json['sunlight'] as String?,
      watering: json['watering'] as String?,
      careDifficulty: json['careDifficulty'] as String?,
      isIndoor: json['isIndoor'] as bool?,
      isOutdoor: json['isOutdoor'] as bool?,
      isPetSafe: json['isPetSafe'] as bool?,
      sizeCm: json['sizeCm'] as int?,
      climate: (json['climate'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      nurseryId: (json['nurseryId'] as String?) ?? (nurseryMap?['id'] as String? ?? ''),
      nurseryName: nurseryMap?['name'] as String?,
      nurseryCity: nurseryMap?['city'] as String?,
      nurseryState: nurseryMap?['state'] as String?,
      nurseryAddress: nurseryMap?['address'] as String?,
      nurseryLogoUrl: (nurseryMap?['logoUrl'] ?? nurseryMap?['imageUrl']) as String?,
    );
  }

  Plant copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    double? price,
    int? stock,
    bool? isActive,
    String? sunlight,
    String? watering,
    String? careDifficulty,
    bool? isIndoor,
    bool? isOutdoor,
    bool? isPetSafe,
    int? sizeCm,
    List<String>? climate,
    List<String>? tags,
    String? nurseryId,
    String? nurseryName,
    String? nurseryCity,
    String? nurseryState,
    String? nurseryAddress,
    String? nurseryLogoUrl,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      sunlight: sunlight ?? this.sunlight,
      watering: watering ?? this.watering,
      careDifficulty: careDifficulty ?? this.careDifficulty,
      isIndoor: isIndoor ?? this.isIndoor,
      isOutdoor: isOutdoor ?? this.isOutdoor,
      isPetSafe: isPetSafe ?? this.isPetSafe,
      sizeCm: sizeCm ?? this.sizeCm,
      climate: climate ?? this.climate,
      tags: tags ?? this.tags,
      nurseryId: nurseryId ?? this.nurseryId,
      nurseryName: nurseryName ?? this.nurseryName,
      nurseryCity: nurseryCity ?? this.nurseryCity,
      nurseryState: nurseryState ?? this.nurseryState,
      nurseryAddress: nurseryAddress ?? this.nurseryAddress,
      nurseryLogoUrl: nurseryLogoUrl ?? this.nurseryLogoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (category != null) 'category': category,
      'price': price,
      'stock': stock,
      'isActive': isActive,
      if (sunlight != null) 'sunlight': sunlight,
      if (watering != null) 'watering': watering,
      if (careDifficulty != null) 'careDifficulty': careDifficulty,
      if (isIndoor != null) 'isIndoor': isIndoor,
      if (isOutdoor != null) 'isOutdoor': isOutdoor,
      if (isPetSafe != null) 'isPetSafe': isPetSafe,
      if (sizeCm != null) 'sizeCm': sizeCm,
      'climate': climate,
      'tags': tags,
      'nurseryId': nurseryId,
      if (nurseryName != null || nurseryCity != null || nurseryState != null || nurseryAddress != null || nurseryLogoUrl != null)
        'nursery': {
          'id': nurseryId,
          if (nurseryName != null) 'name': nurseryName,
          if (nurseryCity != null) 'city': nurseryCity,
          if (nurseryState != null) 'state': nurseryState,
          if (nurseryAddress != null) 'address': nurseryAddress,
          if (nurseryLogoUrl != null) 'logoUrl': nurseryLogoUrl,
        },
    };
  }

  bool get inStock => stock > 0;
  bool get isOutOfStock => stock <= 0;
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  bool get isMedicinal {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('medicinal') || cat.contains('herb')) return true;
    if (tags.any((t) => t.toLowerCase().contains('medicinal') || t.toLowerCase().contains('herb'))) return true;
    final desc = (description ?? '').toLowerCase();
    return desc.contains('medicinal') || desc.contains('ayurvedic');
  }

  String get nurseryLocationDisplay {
    final parts = [nurseryCity, nurseryState].where((p) => p != null && p.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    if (nurseryAddress != null && nurseryAddress!.trim().isNotEmpty) return nurseryAddress!;
    return '';
  }

  String get placementLabel {
    if (isIndoor == true && isOutdoor == true) return 'Indoor & Outdoor';
    if (isIndoor == true) return 'Indoor';
    if (isOutdoor == true) return 'Outdoor';
    return 'Any';
  }
}
