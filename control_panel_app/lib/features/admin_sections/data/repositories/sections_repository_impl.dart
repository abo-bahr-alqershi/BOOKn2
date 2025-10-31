import 'package:bookn_cp_app/core/enums/section_display_style.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/section_item_dto.dart';
import '../../domain/entities/section.dart' as domain;
import '../../domain/entities/property_in_section.dart' as domain;
import '../../domain/entities/unit_in_section.dart' as domain;
import '../../domain/repositories/sections_repository.dart';
import '../datasources/sections_remote_datasource.dart';
import '../datasources/sections_local_datasource.dart';
import '../models/section_model.dart';
import '../models/property_in_section_model.dart';
import '../models/unit_in_section_model.dart';
import '../../../../core/enums/section_target.dart';
import '../../../../core/enums/section_type.dart';
import '../../../../core/enums/section_content_type.dart';

class SectionsRepositoryImpl implements SectionsRepository {
  final SectionsRemoteDataSource remoteDataSource;
  final SectionsLocalDataSource localDataSource;

  SectionsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResult<domain.Section>>> getSections({
    int? pageNumber,
    int? pageSize,
    SectionTarget? target,
    SectionTypeEnum? type,
    SectionContentType? contentType,
  }) async {
    try {
      final result = await remoteDataSource.getSections(
        pageNumber: pageNumber,
        pageSize: pageSize,
        target: target?.apiValue,
        type: type?.value,
        contentType: contentType?.apiValue,
      );
      // Cache latest list
      await localDataSource.cacheSections(result.items);
      return Right(
        PaginatedResult<domain.Section>(
          items: result.items.map((m) => m.toEntity()).toList(),
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          metadata: result.metadata,
        ),
      );
    } catch (e) {
      final cached = localDataSource.getCachedSections();
      if (cached.isNotEmpty) {
        final items = cached.map((e) => e.toEntity()).toList();
        return Right(
          PaginatedResult<domain.Section>(
            items: items,
            pageNumber: pageNumber ?? 1,
            pageSize: pageSize ?? items.length,
            totalCount: items.length,
          ),
        );
      }
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, domain.Section>> getSectionById(
      String sectionId) async {
    try {
      final model = await remoteDataSource.getSectionById(sectionId);
      return Right(model.toEntity());
    } catch (e) {
      // try from cache
      final cached = localDataSource.getCachedSections();
      final hit = cached.firstWhere(
        (m) => m.id == sectionId,
        orElse: () => const SectionModel(
          id: '',
          type: SectionTypeEnum.singlePropertyAd,
          contentType: SectionContentType.properties,
          displayStyle: SectionDisplayStyle.grid,
          displayOrder: 0,
          target: SectionTarget.properties,
          isActive: true,
          columnsCount: 2,
          itemsToShow: 10,
        ),
      );
      if (hit.id.isNotEmpty) {
        return Right(hit.toEntity());
      }
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, domain.Section>> createSection(
      domain.Section section, {String? tempKey}) async {
    try {
      final model = await remoteDataSource.createSection(SectionModel(
        tempKey: (tempKey != null && tempKey.isNotEmpty) ? tempKey : null,
        id: section.id,
        type: section.type,
        contentType: section.contentType,
        displayStyle: section.displayStyle,
        name: section.name,
        title: section.title,
        subtitle: section.subtitle,
        description: section.description,
        shortDescription: section.shortDescription,
        displayOrder: section.displayOrder,
        target: section.target,
        isActive: section.isActive,
        columnsCount: section.columnsCount,
        itemsToShow: section.itemsToShow,
        icon: section.icon,
        colorTheme: section.colorTheme,
        backgroundImage: section.backgroundImage,
        filterCriteria: section.filterCriteria,
        sortCriteria: section.sortCriteria,
        cityName: section.cityName,
        propertyTypeId: section.propertyTypeId,
        unitTypeId: section.unitTypeId,
        minPrice: section.minPrice,
        maxPrice: section.maxPrice,
        minRating: section.minRating,
        isVisibleToGuests: section.isVisibleToGuests,
        isVisibleToRegistered: section.isVisibleToRegistered,
        requiresPermission: section.requiresPermission,
        startDate: section.startDate,
        endDate: section.endDate,
        metadata: section.metadata,
        categoryClass: section.categoryClass,
        homeItemsCount: section.homeItemsCount,
      ).toJson());
      return Right(model.toEntity());
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, domain.Section>> updateSection(
      String sectionId, domain.Section section) async {
    try {
      final model = await remoteDataSource.updateSection(
          sectionId,
          SectionModel(
            id: section.id,
            type: section.type,
            contentType: section.contentType,
            displayStyle: section.displayStyle,
            name: section.name,
            title: section.title,
            subtitle: section.subtitle,
            description: section.description,
            shortDescription: section.shortDescription,
            displayOrder: section.displayOrder,
            target: section.target,
            isActive: section.isActive,
            columnsCount: section.columnsCount,
            itemsToShow: section.itemsToShow,
            icon: section.icon,
            colorTheme: section.colorTheme,
            backgroundImage: section.backgroundImage,
            filterCriteria: section.filterCriteria,
            sortCriteria: section.sortCriteria,
            cityName: section.cityName,
            propertyTypeId: section.propertyTypeId,
            unitTypeId: section.unitTypeId,
            minPrice: section.minPrice,
            maxPrice: section.maxPrice,
            minRating: section.minRating,
            isVisibleToGuests: section.isVisibleToGuests,
            isVisibleToRegistered: section.isVisibleToRegistered,
            requiresPermission: section.requiresPermission,
            startDate: section.startDate,
            endDate: section.endDate,
            metadata: section.metadata,
            categoryClass: section.categoryClass,
            homeItemsCount: section.homeItemsCount,
          ).toJson());
      return Right(model.toEntity());
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> deleteSection(String sectionId) async {
    try {
      final ok = await remoteDataSource.deleteSection(sectionId);
      return Right(ok);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> toggleSectionStatus(
      String sectionId, bool isActive) async {
    try {
      final ok =
          await remoteDataSource.toggleSectionStatus(sectionId, isActive);
      return Right(ok);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, void>> assignItems(
      String sectionId, AssignSectionItemsDto payload) async {
    try {
      await remoteDataSource.assignItems(sectionId, payload);
      return const Right(null);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, void>> addItems(
      String sectionId, AddItemsToSectionDto payload) async {
    try {
      await remoteDataSource.addItems(sectionId, payload);
      return const Right(null);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, void>> removeItems(
      String sectionId, RemoveItemsFromSectionDto payload) async {
    try {
      await remoteDataSource.removeItems(sectionId, payload);
      return const Right(null);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, void>> reorderItems(
      String sectionId, UpdateItemOrderDto payload) async {
    try {
      await remoteDataSource.reorderItems(sectionId, payload);
      return const Right(null);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<domain.PropertyInSection>>>
      getPropertyItems(String sectionId,
          {int? pageNumber, int? pageSize}) async {
    try {
      final result = await remoteDataSource.getPropertyItems(sectionId,
          pageNumber: pageNumber, pageSize: pageSize);
      return Right(
        PaginatedResult<domain.PropertyInSection>(
          items: result.items.map((e) => e.toEntity()).toList(),
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          metadata: result.metadata,
        ),
      );
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<domain.UnitInSection>>> getUnitItems(
      String sectionId,
      {int? pageNumber,
      int? pageSize}) async {
    try {
      final result = await remoteDataSource.getUnitItems(sectionId,
          pageNumber: pageNumber, pageSize: pageSize);
      return Right(
        PaginatedResult<domain.UnitInSection>(
          items: result.items.map((e) => e.toEntity()).toList(),
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          metadata: result.metadata,
        ),
      );
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }
}
