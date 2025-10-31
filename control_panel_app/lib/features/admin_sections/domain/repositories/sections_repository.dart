import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/section.dart';
import '../../domain/entities/property_in_section.dart';
import '../../domain/entities/unit_in_section.dart';
import '../../../../core/models/section_item_dto.dart';
import '../../../../core/enums/section_target.dart';
import '../../../../core/enums/section_type.dart';
import '../../../../core/enums/section_content_type.dart';

abstract class SectionsRepository {
  Future<Either<Failure, PaginatedResult<Section>>> getSections({
    int? pageNumber,
    int? pageSize,
    SectionTarget? target,
    SectionTypeEnum? type,
    SectionContentType? contentType,
  });

  Future<Either<Failure, Section>> getSectionById(String sectionId);

  Future<Either<Failure, Section>> createSection(Section section, {String? tempKey});
  Future<Either<Failure, Section>> updateSection(String sectionId, Section section);
  Future<Either<Failure, bool>> deleteSection(String sectionId);
  Future<Either<Failure, bool>> toggleSectionStatus(String sectionId, bool isActive);

  Future<Either<Failure, void>> assignItems(String sectionId, AssignSectionItemsDto payload);
  Future<Either<Failure, void>> addItems(String sectionId, AddItemsToSectionDto payload);
  Future<Either<Failure, void>> removeItems(String sectionId, RemoveItemsFromSectionDto payload);
  Future<Either<Failure, void>> reorderItems(String sectionId, UpdateItemOrderDto payload);

  Future<Either<Failure, PaginatedResult<PropertyInSection>>> getPropertyItems(String sectionId, {int? pageNumber, int? pageSize});
  Future<Either<Failure, PaginatedResult<UnitInSection>>> getUnitItems(String sectionId, {int? pageNumber, int? pageSize});
}

