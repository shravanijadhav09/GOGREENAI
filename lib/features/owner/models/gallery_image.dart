class GalleryCategories {
  static const String indoor = 'Indoor Plants';
  static const String outdoor = 'Outdoor Plants';
  static const String medicinal = 'Medicinal / Aushadhi Plants';
  static const String general = 'General';

  static const String indoorPlants = indoor;

  static const List<String> all = [
    indoor,
    outdoor,
    medicinal,
    general,
  ];
}

class GalleryImage {
  final String id;
  final String url;
  final String? publicId;
  final String? caption;
  final String? category;
  final int sortOrder;
  final String nurseryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GalleryImage({
    required this.id,
    required this.url,
    this.publicId,
    this.caption,
    this.category,
    this.sortOrder = 0,
    required this.nurseryId,
    this.createdAt,
    this.updatedAt,
  });

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      publicId: json['publicId'] as String?,
      caption: json['caption'] as String?,
      category: json['category'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      nurseryId: json['nurseryId'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (publicId != null) 'publicId': publicId,
      if (caption != null) 'caption': caption,
      if (category != null) 'category': category,
      'sortOrder': sortOrder,
      'nurseryId': nurseryId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  GalleryImage copyWith({
    String? id,
    String? url,
    String? publicId,
    String? caption,
    String? category,
    int? sortOrder,
    String? nurseryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GalleryImage(
      id: id ?? this.id,
      url: url ?? this.url,
      publicId: publicId ?? this.publicId,
      caption: caption ?? this.caption,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      nurseryId: nurseryId ?? this.nurseryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryImage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url &&
          caption == other.caption &&
          category == other.category &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      url.hashCode ^
      caption.hashCode ^
      category.hashCode ^
      sortOrder.hashCode;
}
