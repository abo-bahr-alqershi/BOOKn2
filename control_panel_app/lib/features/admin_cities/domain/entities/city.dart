import 'package:equatable/equatable.dart';

/// 🏙️ City Entity - كيان المدينة
class City extends Equatable {
  final String name;
  final String country;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? propertiesCount;
  final bool? isActive;
  final Map<String, dynamic>? metadata;

  const City({
    required this.name,
    required this.country,
    required this.images,
    this.createdAt,
    this.updatedAt,
    this.propertiesCount,
    this.isActive = true,
    this.metadata,
  });

  /// نسخة فارغة للإنشاء
  factory City.empty() => const City(
    name: '',
    country: '',
    images: [],
  );

  /// نسخ مع التعديل
  City copyWith({
    String? name,
    String? country,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? propertiesCount,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return City(
      name: name ?? this.name,
      country: country ?? this.country,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      propertiesCount: propertiesCount ?? this.propertiesCount,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    name,
    country,
    images,
    createdAt,
    updatedAt,
    propertiesCount,
    isActive,
    metadata,
  ];
}