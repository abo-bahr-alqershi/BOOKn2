import 'package:equatable/equatable.dart';
import '../../../search/domain/entities/search_filter.dart' show UnitTypeField;

class UnitType extends Equatable {
  final String id;
  final String propertyTypeId;
  final String name;
  final String description;
  final String icon;
  final int maxCapacity;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;
  final List<UnitTypeField> fields;

  const UnitType({
    required this.id,
    required this.propertyTypeId,
    required this.name,
    required this.description,
    required this.icon,
    required this.maxCapacity,
    required this.isHasAdults,
    required this.isHasChildren,
    required this.isMultiDays,
    required this.isRequiredToDetermineTheHour,
    this.fields = const [],
  });

  @override
  List<Object?> get props => [
        id,
        propertyTypeId,
        name,
        description,
        maxCapacity,
        icon,
        isHasAdults,
        isHasChildren,
        isMultiDays,
        isRequiredToDetermineTheHour,
        fields,
      ];
}