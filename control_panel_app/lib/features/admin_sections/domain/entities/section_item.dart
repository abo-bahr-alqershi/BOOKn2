import 'package:equatable/equatable.dart';

class SectionItem extends Equatable {
  final String id;
  final String sectionId;
  final String? propertyId;
  final String? unitId;
  final int sortOrder;

  const SectionItem({
    required this.id,
    required this.sectionId,
    this.propertyId,
    this.unitId,
    required this.sortOrder,
  });

  @override
  List<Object?> get props => [id, sectionId, propertyId, unitId, sortOrder];
}

