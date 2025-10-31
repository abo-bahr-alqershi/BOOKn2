import '../../domain/entities/section_item.dart' as domain;

class SectionItemModel {
  final String id;
  final String sectionId;
  final String? propertyId;
  final String? unitId;
  final int sortOrder;

  const SectionItemModel({
    required this.id,
    required this.sectionId,
    this.propertyId,
    this.unitId,
    required this.sortOrder,
  });

  factory SectionItemModel.fromJson(Map<String, dynamic> json) {
    return SectionItemModel(
      id: json['id']?.toString() ?? '',
      sectionId: json['sectionId']?.toString() ?? '',
      propertyId: json['propertyId']?.toString(),
      unitId: json['unitId']?.toString(),
      sortOrder: (json['sortOrder'] is int)
          ? json['sortOrder']
          : int.tryParse('${json['sortOrder'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sectionId': sectionId,
        'propertyId': propertyId,
        'unitId': unitId,
        'sortOrder': sortOrder,
      };

  domain.SectionItem toEntity() => domain.SectionItem(
        id: id,
        sectionId: sectionId,
        propertyId: propertyId,
        unitId: unitId,
        sortOrder: sortOrder,
      );
}

