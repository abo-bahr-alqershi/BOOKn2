import 'package:bookn_cp_app/features/admin_units/domain/entities/money.dart';
import 'package:bookn_cp_app/features/admin_units/domain/entities/unit_field_value.dart';

import '../../domain/entities/unit.dart';
import '../../domain/entities/pricing_method.dart';
import 'money_model.dart';
import 'unit_field_value_model.dart';

class UnitModel extends Unit {
  const UnitModel({
    required String id,
    required String propertyId,
    required String unitTypeId,
    required String name,
    required Money basePrice,
    int maxCapacity = 2,
    double discountPercentage = 0.0,
    required String customFeatures,
    required bool isAvailable,
    int viewCount = 0,
    int bookingCount = 0,
    int? adultsCapacity,
    int? childrenCapacity,
    required String propertyName,
    required String unitTypeName,
    required PricingMethod pricingMethod,
    List<UnitFieldValue> fieldValues = const [],
    List<FieldGroupWithValues> dynamicFields = const [],
    double? distanceKm,
    List<String>? images,
    bool allowsCancellation = true,
    int? cancellationWindowDays,
  }) : super(
          id: id,
          propertyId: propertyId,
          unitTypeId: unitTypeId,
          name: name,
          basePrice: basePrice,
          maxCapacity: maxCapacity,
          discountPercentage: discountPercentage,
          customFeatures: customFeatures,
          isAvailable: isAvailable,
          viewCount: viewCount,
          bookingCount: bookingCount,
          adultsCapacity: adultsCapacity,
          childrenCapacity: childrenCapacity,
          propertyName: propertyName,
          unitTypeName: unitTypeName,
          pricingMethod: pricingMethod,
          fieldValues: fieldValues,
          dynamicFields: dynamicFields,
          distanceKm: distanceKm,
          images: images,
          allowsCancellation: allowsCancellation,
          cancellationWindowDays: cancellationWindowDays,
        );

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    // Robust parsing for cancellationWindowDays in case backend returns as num/string
    final dynamic _cwdRaw = json['cancellationWindowDays'];
    final int? _cwd = _cwdRaw == null
        ? null
        : (_cwdRaw is int
            ? _cwdRaw
            : (_cwdRaw is num
                ? _cwdRaw.toInt()
                : (int.tryParse(_cwdRaw.toString()))));

    return UnitModel(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      unitTypeId: json['unitTypeId'] as String,
      name: json['name'] as String,
      basePrice: MoneyModel.fromJson(json['basePrice']),
      maxCapacity: json['maxCapacity'] as int? ?? 2,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      customFeatures: json['customFeatures'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool,
      viewCount: json['viewCount'] as int? ?? 0,
      bookingCount: json['bookingCount'] as int? ?? 0,
      adultsCapacity: json['adultsCapacity'] as int?,
      childrenCapacity: json['childrenCapacity'] as int?,
      propertyName: json['propertyName'] as String,
      unitTypeName: json['unitTypeName'] as String,
      pricingMethod: PricingMethod.fromString(json['pricingMethod'] as String),
      fieldValues: (json['fieldValues'] as List?)
              ?.map((e) => UnitFieldValueModel.fromJson(e))
              .toList() ??
          [],
      dynamicFields: (json['dynamicFields'] as List?)
              ?.map((e) => FieldGroupWithValuesModel.fromJson(e))
              .toList() ??
          [],
      distanceKm: json['distanceKm'] as double?,
      images: (json['images'] as List?)
              ?.map((e) => e['url'] as String)
              .toList() ??
          [],
      allowsCancellation: json['allowsCancellation'] as bool? ?? true,
      cancellationWindowDays: _cwd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'unitTypeId': unitTypeId,
      'name': name,
      'basePrice': MoneyModel.fromEntity(basePrice).toJson(),
      'maxCapacity': maxCapacity,
      'discountPercentage': discountPercentage,
      'customFeatures': customFeatures,
      'isAvailable': isAvailable,
      'viewCount': viewCount,
      'bookingCount': bookingCount,
      if (adultsCapacity != null) 'adultsCapacity': adultsCapacity,
      if (childrenCapacity != null) 'childrenCapacity': childrenCapacity,
      'propertyName': propertyName,
      'unitTypeName': unitTypeName,
      'pricingMethod': pricingMethod.value,
      'fieldValues': fieldValues
          .map((e) => UnitFieldValueModel.fromEntity(e).toJson())
          .toList(),
      'dynamicFields': dynamicFields
          .map((e) => FieldGroupWithValuesModel.fromEntity(e).toJson())
          .toList(),
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (images != null) 'images': images,
      'allowsCancellation': allowsCancellation,
      if (cancellationWindowDays != null) 'cancellationWindowDays': cancellationWindowDays,
    };
  }
}