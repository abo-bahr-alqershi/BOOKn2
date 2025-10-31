import 'package:equatable/equatable.dart';

class SectionFilterCriteria extends Equatable {
  final String? cityName;
  final String? propertyTypeId;
  final String? unitTypeId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final Map<String, dynamic>? extra;

  const SectionFilterCriteria({
    this.cityName,
    this.propertyTypeId,
    this.unitTypeId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.extra,
  });

  Map<String, dynamic> toMap() {
    return {
      if (cityName != null) 'cityName': cityName,
      if (propertyTypeId != null) 'propertyTypeId': propertyTypeId,
      if (unitTypeId != null) 'unitTypeId': unitTypeId,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minRating != null) 'minRating': minRating,
      if (extra != null) ...extra!,
    };
  }

  @override
  List<Object?> get props => [
        cityName,
        propertyTypeId,
        unitTypeId,
        minPrice,
        maxPrice,
        minRating,
        extra,
      ];
}

