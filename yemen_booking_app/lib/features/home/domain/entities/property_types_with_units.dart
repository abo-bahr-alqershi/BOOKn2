import 'property_type.dart';
import 'unit_type.dart';

class PropertyTypesWithUnits {
  final List<PropertyType> propertyTypes;
  final Map<String, List<UnitType>> unitTypesByPropertyTypeId;

  const PropertyTypesWithUnits({
    required this.propertyTypes,
    required this.unitTypesByPropertyTypeId,
  });
}
