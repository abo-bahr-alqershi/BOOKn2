import 'package:equatable/equatable.dart';

class PropertyType extends Equatable {
  final String id;
  final String name;
  final String description;
  final int propertiesCount;
  final String icon;
  final int count;
  final List<String> defaultAmenities;
  final List<String> unitTypeIds;

  const PropertyType({
    required this.id,
    required this.name,
    required this.description,
    required this.propertiesCount,
    required this.icon,
    this.count = 0,
    this.defaultAmenities = const [],
    this.unitTypeIds = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        propertiesCount,
        defaultAmenities,
        icon,
        count,
        unitTypeIds,
      ];
}
