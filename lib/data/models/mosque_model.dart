/// Mosque model for admin dashboard
/// Matches actual Supabase schema: is_verified boolean, no status/submitted_by/is_active
class MosqueModel {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final List<String> facilities;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MosqueModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.facilities = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'] as List)
          : [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for insert (without id and timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'facilities': facilities,
      'is_verified': isVerified,
    };
  }

  /// Copy with new values
  MosqueModel copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? facilities,
    double? rating,
    int? reviewCount,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MosqueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      facilities: facilities ?? this.facilities,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get full address string
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  /// Get short location (city, province)
  String get shortLocation {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }

  /// Status display text
  String get statusDisplay => isVerified ? 'Verified' : 'Unverified';

  @override
  String toString() {
    return 'MosqueModel(id: $id, name: $name, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MosqueModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
