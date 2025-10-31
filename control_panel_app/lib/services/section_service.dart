import 'package:bookn_cp_app/core/enums/section_target.dart';
import 'package:bookn_cp_app/core/enums/section_type.dart';
import 'package:bookn_cp_app/core/enums/section_content_type.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/entities/section.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/create_section_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/delete_section_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/get_all_sections_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/toggle_section_status_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/get_section_by_id_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/sections/update_section_usecase.dart';

class SectionService {
  final GetAllSectionsUseCase getAllSections;
  final CreateSectionUseCase createSection;
  final UpdateSectionUseCase updateSection;
  final DeleteSectionUseCase deleteSection;
  final ToggleSectionStatusUseCase toggleStatus;
  final GetSectionByIdUseCase getById;

  const SectionService({
    required this.getAllSections,
    required this.createSection,
    required this.updateSection,
    required this.deleteSection,
    required this.toggleStatus,
    required this.getById,
  });

  Future<PaginatedResult<Section>> fetchSections({
    int? pageNumber,
    int? pageSize,
    SectionTarget? target,
    SectionTypeEnum? type,
    SectionContentType? contentType,
  }) async {
    final result = await getAllSections(GetAllSectionsParams(
      pageNumber: pageNumber,
      pageSize: pageSize,
      target: target,
      type: type,
      contentType: contentType,
    ));
    return result.fold((l) => PaginatedResult.empty(), (r) => r);
  }

  Future<Section?> create(Section section) async {
    final result = await createSection(CreateSectionParams(section));
    return result.fold((l) => null, (r) => r);
  }

  Future<Section?> update(String sectionId, Section section) async {
    final result = await updateSection(UpdateSectionParams(sectionId: sectionId, section: section));
    return result.fold((l) => null, (r) => r);
  }

  // Note: Background image for Section is textual (URL). Use the unified images API to upload media
  // and then set the `backgroundImage` string on the Section via update().

  Future<bool> remove(String sectionId) async {
    final result = await deleteSection(DeleteSectionParams(sectionId));
    return result.fold((l) => false, (r) => r);
  }

  Future<bool> setActive(String sectionId, bool isActive) async {
    final result = await toggleStatus(ToggleSectionStatusParams(sectionId: sectionId, isActive: isActive));
    return result.fold((l) => false, (r) => r);
  }

  Future<Section?> fetchById(String sectionId) async {
    final result = await getById(GetSectionByIdParams(sectionId));
    return result.fold((l) => null, (r) => r);
  }
}

