// lib/features/home/presentation/widgets/sections/models/section_display_item.dart

import 'package:equatable/equatable.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';

/// Abstract class representing any item that can be displayed in a section
abstract class SectionDisplayItem extends Equatable {
  const SectionDisplayItem();
  String get id;
  String get name;
  String? get imageUrl;
  double get price;
  double? get discountedPrice;
  int? get discount;
  bool get isAvailable;

  // Location info (for properties)
  String? get location => null;
  String? get city => null;
  double? get latitude => null;
  double? get longitude => null;
  String? get category => null;

  // Property-specific info
  int? get starRating => null;
  double? get averageRating => null;
  int? get reviewsCount => null;
  int? get bedrooms => null;
  int? get bathrooms => null;
  double? get area => null;

  // Unit-specific info
  int? get maxCapacity => null;
  String? get unitTypeId => null;
  String? get propertyId => null;
  String? get propertyName => null;

  // Common display helpers
  bool get hasDiscount => discount != null && discount! > 0;
  String get displayPrice => discountedPrice != null && discountedPrice! > 0
      ? discountedPrice!.toStringAsFixed(0)
      : price.toStringAsFixed(0);

  // Factory to create from either property or unit
  factory SectionDisplayItem.fromProperty(SectionPropertyItemModel property) {
    return PropertyDisplayItem(property);
  }

  factory SectionDisplayItem.fromUnit(SectionUnitItemModel unit) {
    return UnitDisplayItem(unit);
  }
}

/// Implementation for property items
class PropertyDisplayItem extends SectionDisplayItem {
  final SectionPropertyItemModel property;

  const PropertyDisplayItem(this.property) : super();

  @override
  String get id => property.id;

  @override
  String get name => property.name;

  @override
  String? get imageUrl => property.imageUrl;

  @override
  double get price => property.price ?? property.minPrice;

  @override
  double? get discountedPrice =>
      property.discountedPrice > 0 ? property.discountedPrice : null;

  @override
  int? get discount => property.discount;

  @override
  bool get isAvailable => property.isAvailable;

  @override
  String? get location => property.location;

  @override
  String? get city => property.city;

  @override
  double? get latitude => property.latitude;

  @override
  double? get longitude => property.longitude;

  @override
  String? get category =>
      property.propertyType.isNotEmpty ? property.propertyType : null;

  @override
  int? get starRating => property.starRating;

  @override
  double? get averageRating => property.averageRating;

  @override
  int? get reviewsCount => property.reviewsCount;

  @override
  int? get bedrooms => property.bedrooms;

  @override
  int? get bathrooms => property.bathrooms;

  @override
  double? get area => property.area;

  @override
  List<Object?> get props => [property];
}

/// Implementation for unit items
class UnitDisplayItem extends SectionDisplayItem {
  final SectionUnitItemModel unit;

  const UnitDisplayItem(this.unit) : super();

  @override
  String get id => unit.id;

  @override
  String get name => unit.name;

  @override
  String? get imageUrl => unit.imageUrl;

  @override
  double get price => unit.price ?? unit.minPrice;

  @override
  double? get discountedPrice =>
      unit.discountedPrice > 0 ? unit.discountedPrice : null;

  @override
  int? get discount => unit.discount;

  @override
  bool get isAvailable => unit.isAvailable;

  @override
  int? get maxCapacity => unit.maxCapacity;

  @override
  String? get unitTypeId => unit.unitTypeId;

  @override
  String? get propertyId => unit.propertyId;

  @override
  String? get category =>
      unit.unitTypeId?.isNotEmpty == true ? unit.unitTypeId : null;

  @override
  List<Object?> get props => [unit];
}

/// Extension to convert lists
extension SectionDisplayItemListExt on List<dynamic> {
  List<SectionDisplayItem> toDisplayItems() {
    return map((item) {
      if (item is SectionPropertyItemModel) {
        return SectionDisplayItem.fromProperty(item);
      } else if (item is SectionUnitItemModel) {
        return SectionDisplayItem.fromUnit(item);
      }
      throw ArgumentError('Unknown item type: ${item.runtimeType}');
    }).toList();
  }
}
