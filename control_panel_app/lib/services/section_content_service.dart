import 'package:bookn_cp_app/core/enums/section_target.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart' as core;
import 'package:bookn_cp_app/core/models/section_item_dto.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/entities/property_in_section.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/entities/unit_in_section.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/section_items/add_items_to_section_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/section_items/get_section_items_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/section_items/remove_items_from_section_usecase.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/usecases/section_items/update_item_order_usecase.dart';

class SectionContentService {
  final GetSectionItemsUseCase getItems;
  final AddItemsToSectionUseCase addItems;
  final RemoveItemsFromSectionUseCase removeItems;
  final UpdateItemOrderUseCase reorderItems;

  const SectionContentService({
    required this.getItems,
    required this.addItems,
    required this.removeItems,
    required this.reorderItems,
  });

  Future<core.PaginatedResult<dynamic>> fetchItems({
    required String sectionId,
    required SectionTarget target,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final result = await getItems(GetSectionItemsParams(
      sectionId: sectionId,
      target: target,
      pageNumber: pageNumber,
      pageSize: pageSize,
    ));
    return result.fold((l) => core.PaginatedResult.empty(pageNumber: pageNumber, pageSize: pageSize), (r) => r);
  }

  Future<bool> add({required String sectionId, List<String> propertyIds = const [], List<String> unitIds = const []}) async {
    final payload = AddItemsToSectionDto(propertyIds: propertyIds, unitIds: unitIds);
    final result = await addItems(AddItemsToSectionParams(sectionId: sectionId, payload: payload));
    return result.fold((l) => false, (r) => true);
  }

  Future<bool> remove({required String sectionId, required List<String> itemIds}) async {
    final payload = RemoveItemsFromSectionDto(itemIds: itemIds);
    final result = await removeItems(RemoveItemsFromSectionParams(sectionId: sectionId, payload: payload));
    return result.fold((l) => false, (r) => true);
  }

  Future<bool> reorder({required String sectionId, required List<ItemOrderDto> orders}) async {
    final payload = UpdateItemOrderDto(orders: orders);
    final result = await reorderItems(UpdateItemOrderParams(sectionId: sectionId, payload: payload));
    return result.fold((l) => false, (r) => true);
  }
}

