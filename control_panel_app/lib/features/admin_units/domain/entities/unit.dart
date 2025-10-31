import 'package:equatable/equatable.dart';
import 'money.dart';
import 'pricing_method.dart';
import 'unit_field_value.dart';

class Unit extends Equatable {
  final String id;
  final String propertyId;
  final String unitTypeId;
  final String name;
  final Money basePrice;
  final int maxCapacity;
  final double discountPercentage;
  final String customFeatures;
  final bool isAvailable;
  final int viewCount;
  final int bookingCount;
  final int? adultsCapacity;
  final int? childrenCapacity;
  final String propertyName;
  final String unitTypeName;
  final PricingMethod pricingMethod;
  final List<UnitFieldValue> fieldValues;
  final List<FieldGroupWithValues> dynamicFields;
  final double? distanceKm;
  final List<String>? images;
  final bool allowsCancellation;
  final int? cancellationWindowDays;

  const Unit({
    required this.id,
    required this.propertyId,
    required this.unitTypeId,
    required this.name,
    required this.basePrice,
    this.maxCapacity = 2,
    this.discountPercentage = 0.0,
    required this.customFeatures,
    required this.isAvailable,
    this.viewCount = 0,
    this.bookingCount = 0,
    this.adultsCapacity,
    this.childrenCapacity,
    required this.propertyName,
    required this.unitTypeName,
    required this.pricingMethod,
    this.fieldValues = const [],
    this.dynamicFields = const [],
    this.distanceKm,
    this.images,
    this.allowsCancellation = true,
    this.cancellationWindowDays,
  });

  List<String> get featuresList {
    if (customFeatures.isEmpty) return [];
    return customFeatures.split(',').map((e) => e.trim()).toList();
  }

  String get capacityDisplay {
    final capacities = <String>[];
    if (adultsCapacity != null) capacities.add('👨 $adultsCapacity');
    if (childrenCapacity != null) capacities.add('👶 $childrenCapacity');
    return capacities.join(' • ');
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        unitTypeId,
        name,
        basePrice,
        maxCapacity,
        discountPercentage,
        customFeatures,
        isAvailable,
        viewCount,
        bookingCount,
        adultsCapacity,
        childrenCapacity,
        propertyName,
        unitTypeName,
        pricingMethod,
        fieldValues,
        dynamicFields,
        distanceKm,
        images,
        allowsCancellation,
        cancellationWindowDays,
      ];
}