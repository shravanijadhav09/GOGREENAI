import 'dart:math' as math;

class Nursery {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? phone;
  final String? email;
  final String? imageUrl;
  final String? logoUrl;
  final bool isVerified;
  final bool isActive;
  final String? ownerId;
  final int? plantCount;
  final double averageRating;
  final int totalRatings;

  // Payment settings
  final String? upiId;
  final String? upiQrUrl;
  final String? upiQrPublicId;
  final bool isUpiEnabled;
  final bool isPayAtPickupEnabled;
  final bool isCodEnabled;

  // Geographic coordinates
  final double? latitude;
  final double? longitude;

  Nursery({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.state,
    this.phone,
    this.email,
    this.imageUrl,
    this.logoUrl,
    this.isVerified = false,
    this.isActive = true,
    this.ownerId,
    this.plantCount,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.upiId,
    this.upiQrUrl,
    this.upiQrPublicId,
    this.isUpiEnabled = false,
    this.isPayAtPickupEnabled = true,
    this.isCodEnabled = false,
    this.latitude,
    this.longitude,
  });

  factory Nursery.fromJson(Map<String, dynamic> json) {
    final logo = (json['logoUrl'] ?? json['imageUrl']) as String?;
    final avgRating = json['averageRating'] != null
        ? double.tryParse(json['averageRating'].toString()) ?? 0.0
        : 0.0;
    final totalR = json['totalRatings'] != null
        ? int.tryParse(json['totalRatings'].toString()) ?? 0
        : 0;

    return Nursery(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      phone: json['phone'] as String?,
      email: (json['email'] ?? json['owner']?['email']) as String?,
      imageUrl: logo,
      logoUrl: logo,
      isVerified: (json['isVerified'] as bool?) ?? false,
      isActive: (json['isActive'] as bool?) ?? true,
      ownerId: json['ownerId'] as String?,
      plantCount: json['_count']?['plants'] as int?,
      averageRating: avgRating,
      totalRatings: totalR,
      upiId: json['upiId'] as String?,
      upiQrUrl: json['upiQrUrl'] as String?,
      upiQrPublicId: json['upiQrPublicId'] as String?,
      isUpiEnabled: (json['isUpiEnabled'] as bool?) ?? false,
      isPayAtPickupEnabled: (json['isPayAtPickupEnabled'] as bool?) ?? true,
      isCodEnabled: (json['isCodEnabled'] as bool?) ?? false,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  Nursery copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? phone,
    String? email,
    String? imageUrl,
    String? logoUrl,
    bool? isVerified,
    bool? isActive,
    String? ownerId,
    int? plantCount,
    double? averageRating,
    int? totalRatings,
    String? upiId,
    String? upiQrUrl,
    String? upiQrPublicId,
    bool? isUpiEnabled,
    bool? isPayAtPickupEnabled,
    bool? isCodEnabled,
    double? latitude,
    double? longitude,
  }) {
    return Nursery(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,
      plantCount: plantCount ?? this.plantCount,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      upiId: upiId ?? this.upiId,
      upiQrUrl: upiQrUrl ?? this.upiQrUrl,
      upiQrPublicId: upiQrPublicId ?? this.upiQrPublicId,
      isUpiEnabled: isUpiEnabled ?? this.isUpiEnabled,
      isPayAtPickupEnabled: isPayAtPickupEnabled ?? this.isPayAtPickupEnabled,
      isCodEnabled: isCodEnabled ?? this.isCodEnabled,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Calculates straight-line distance in kilometers using the Haversine formula
  double? distanceFrom(double? userLat, double? userLng) {
    if (userLat == null || userLng == null || latitude == null || longitude == null) {
      return null;
    }
    return _computeHaversine(userLat, userLng, latitude!, longitude!);
  }

  static double _computeHaversine(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);

    final rLat1 = lat1 * (math.pi / 180.0);
    final rLat2 = lat2 * (math.pi / 180.0);

    final sinDLat = math.sin(dLat / 2.0);
    final sinDLon = math.sin(dLon / 2.0);
    final a = sinDLat * sinDLat +
        math.cos(rLat1) * math.cos(rLat2) * sinDLon * sinDLon;
    final c = 2.0 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
    return earthRadiusKm * c;
  }

  String? distanceDisplayFrom(double? userLat, double? userLng) {
    final d = distanceFrom(userLat, userLng);
    if (d == null) return null;
    if (d < 1.0) {
      return '${(d * 1000).toStringAsFixed(0)} m away';
    }
    return '${d.toStringAsFixed(1)} km away';
  }

  String get locationDisplay {
    final parts = [city, state].where((p) => p != null && p.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    if (address != null && address!.trim().isNotEmpty) return address!;
    return 'Location not specified';
  }
}
