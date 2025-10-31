import '../../domain/entities/city.dart';

/// 🏙️ City Model for API communication
class CityModel extends City {
  const CityModel({
    required super.name,
    required super.country,
    required super.images,
    super.createdAt,
    super.updatedAt,
    super.propertiesCount,
    super.isActive = null,
    super.metadata,
  });

  /// تحويل من JSON
  factory CityModel.fromJson(Map<String, dynamic> json) {
    List<String> rawImages = [];
    if (json['images'] != null) {
      try {
        rawImages = List<String>.from(json['images']);
      } catch (_) {}
    }
    final sanitized = rawImages.where((u) {
      final val = (u ?? '').toString().trim();
      if (val.isEmpty) return false;
      final lower = val.toLowerCase();
      // Keep only web/relative server paths; drop android local cache paths
      if (lower.startsWith('http://') || lower.startsWith('https://'))
        return true;
      if (lower.startsWith('/uploads') || lower.startsWith('uploads/'))
        return true;
      // Also accept known public folders
      if (lower.startsWith('/images') || lower.startsWith('images/'))
        return true;
      // Drop local device paths like /data/user/0/... or file:// or content://
      if (lower.startsWith('/data/') ||
          lower.startsWith('file://') ||
          lower.startsWith('content://')) return false;
      // Fallback: drop anything else to avoid broken URLs
      return false;
    }).toList(growable: false);

    return CityModel(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      images: sanitized,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      propertiesCount: json['propertiesCount'],
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'],
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'images': images,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'propertiesCount': propertiesCount,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// تحويل من Entity
  factory CityModel.fromEntity(City city) {
    return CityModel(
      name: city.name,
      country: city.country,
      images: city.images,
      createdAt: city.createdAt,
      updatedAt: city.updatedAt,
      propertiesCount: city.propertiesCount,
      isActive: city.isActive,
      metadata: city.metadata,
    );
  }
}
