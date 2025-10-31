import 'property_type_model.dart';
import 'unit_type_model.dart';

class PropertyTypeWithUnitsModel {
  final PropertyTypeModel propertyType;
  final List<UnitTypeModel> unitTypes;

  const PropertyTypeWithUnitsModel({
    required this.propertyType,
    required this.unitTypes,
  });

  factory PropertyTypeWithUnitsModel.fromJson(Map<String, dynamic> json) {
    final pt = PropertyTypeModel.fromJson(json);
    final List<UnitTypeModel> uts = (json['unitTypes'] as List?)
            ?.map((e) => UnitTypeModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <UnitTypeModel>[];
    return PropertyTypeWithUnitsModel(propertyType: pt, unitTypes: uts);
  }
}
