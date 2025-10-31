import 'package:dartz/dartz.dart';
import 'package:yemen_booking_app/core/error/error_handler.dart';
import 'package:yemen_booking_app/core/error/failures.dart';
import 'package:yemen_booking_app/core/network/network_info.dart';
import 'package:yemen_booking_app/core/models/paginated_result.dart' as core;
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/entities/property_type.dart' as domain;
import '../../domain/entities/unit_type.dart' as domain;
import '../../domain/entities/section.dart' as section_domain;
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/property_type_with_units_model.dart';
import '../../domain/entities/property_types_with_units.dart' as combined_domain;

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> recordSectionImpression({
    required String sectionId,
  }) async {
    try {
      // Record impression locally first for immediate response
      await localDataSource.recordSectionImpression(sectionId: sectionId);
      
      // Then try to sync with server if connected
      if (await networkInfo.isConnected) {
        await remoteDataSource.recordSectionImpression(sectionId: sectionId);
      }
      return const Right(null);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, combined_domain.PropertyTypesWithUnits>> getPropertyTypesWithUnits() async {
    if (await networkInfo.isConnected) {
      try {
        final List<PropertyTypeWithUnitsModel> result = await remoteDataSource.getPropertyTypesWithUnits();

        // Map to domain lists
        final propertyTypes = result.map((e) => e.propertyType.toEntity()).toList();
        final Map<String, List<domain.UnitType>> unitTypesByPt = {};
        for (final item in result) {
          unitTypesByPt[item.propertyType.id] = item.unitTypes.map((m) => m.toEntity()).toList();
        }

        return Right(combined_domain.PropertyTypesWithUnits(
          propertyTypes: propertyTypes,
          unitTypesByPropertyTypeId: unitTypesByPt,
        ));
      } catch (e) {
        return ErrorHandler.handle(e);
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, void>> recordSectionInteraction({
    required String sectionId,
    required String interactionType,
    String? itemId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Record interaction locally first
      await localDataSource.recordSectionInteraction(
        sectionId: sectionId,
        interactionType: interactionType,
        itemId: itemId,
        metadata: metadata,
      );
      
      // Then try to sync with server if connected
      if (await networkInfo.isConnected) {
        await remoteDataSource.recordSectionInteraction(
          sectionId: sectionId,
          interactionType: interactionType,
          itemId: itemId,
          metadata: metadata,
        );
      }
      
      return const Right(null);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, core.PaginatedResult<section_domain.Section>>> getSections({
    int pageNumber = 1,
    int pageSize = 10,
    String? target,
    String? type,
    bool forceRefresh = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Try to get fresh data from server
        final result = await remoteDataSource.getSections(
          pageNumber: pageNumber,
          pageSize: pageSize,
          target: target,
          type: type,
        );
        
        // Cache the fresh data
        await localDataSource.cacheSections(result.items);
        
        // Map models to entities
        final mapped = core.PaginatedResult<section_domain.Section>(
          items: result.items.map((m) => m.toEntity()).toList(),
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          metadata: result.metadata,
        );
        
        return Right(mapped);
      } catch (e) {
        // If server fails, try to get cached data
        try {
          final cachedSections = await localDataSource.getCachedSections(
            pageNumber: pageNumber,
            pageSize: pageSize,
            target: target,
            type: type,
          );
          final mapped = core.PaginatedResult<section_domain.Section>(
            items: cachedSections.items.map((m) => m.toEntity()).toList(),
            pageNumber: cachedSections.pageNumber,
            pageSize: cachedSections.pageSize,
            totalCount: cachedSections.totalCount,
            metadata: cachedSections.metadata,
          );
          return Right(mapped);
        } catch (cacheError) {
          return ErrorHandler.handle(e);
        }
      }
    } else {
      // No network, get cached data
      try {
        final cachedSections = await localDataSource.getCachedSections(
          pageNumber: pageNumber,
          pageSize: pageSize,
          target: target,
          type: type,
        );
        final mapped = core.PaginatedResult<section_domain.Section>(
          items: cachedSections.items.map((m) => m.toEntity()).toList(),
          pageNumber: cachedSections.pageNumber,
          pageSize: cachedSections.pageSize,
          totalCount: cachedSections.totalCount,
          metadata: cachedSections.metadata,
        );
        return Right(mapped);
      } catch (e) {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة'));
      }
    }
  }

  @override
  Future<Either<Failure, core.PaginatedResult<SectionPropertyItemModel>>> getSectionPropertyItems({
    required String sectionId,
    int pageNumber = 1,
    int pageSize = 10,
    bool forceRefresh = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Record section impression when fetching items
        await recordSectionImpression(sectionId: sectionId);
        
        // Get fresh data from server
        final result = await remoteDataSource.getSectionPropertyItems(
          sectionId: sectionId,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        
        // Cache the fresh data
        await localDataSource.cacheSectionPropertyItems(
          sectionId: sectionId,
          items: result.items,
        );
        
        return Right(result);
      } catch (e) {
        // If server fails, try to get cached data
        try {
          final cachedItems = await localDataSource.getCachedSectionPropertyItems(
            sectionId: sectionId,
            pageNumber: pageNumber,
            pageSize: pageSize,
          );
          return Right(cachedItems);
        } catch (cacheError) {
          return ErrorHandler.handle(e);
        }
      }
    } else {
      // No network, get cached data
      try {
        final cachedItems = await localDataSource.getCachedSectionPropertyItems(
          sectionId: sectionId,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        return Right(cachedItems);
      } catch (e) {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة'));
      }
    }
  }

  @override
  Future<Either<Failure, List<domain.PropertyType>>> getPropertyTypes() async {
    if (await networkInfo.isConnected) {
      try {
        // Get fresh data from server
        final result = await remoteDataSource.getPropertyTypes();
        
        // Cache the fresh data
        await localDataSource.cachePropertyTypes(result);
        
        return Right(result.map((model) => model.toEntity()).toList());
      } catch (e) {
        // If server fails, try to get cached data
        try {
          final cachedTypes = await localDataSource.getCachedPropertyTypes();
          return Right(cachedTypes.map((model) => model.toEntity()).toList());
        } catch (cacheError) {
          return ErrorHandler.handle(e);
        }
      }
    } else {
      // No network, get cached data
      try {
        final cachedTypes = await localDataSource.getCachedPropertyTypes();
        return Right(cachedTypes.map((model) => model.toEntity()).toList());
      } catch (e) {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة'));
      }
    }
  }

  @override
  Future<Either<Failure, List<domain.UnitType>>> getUnitTypes({
    required String propertyTypeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Get fresh data from server
        final result = await remoteDataSource.getUnitTypes(
          propertyTypeId: propertyTypeId,
        );
        
        // Cache the fresh data
        await localDataSource.cacheUnitTypes(
          propertyTypeId: propertyTypeId,
          unitTypes: result,
        );
        
        return Right(result.map((model) => model.toEntity()).toList());
      } catch (e) {
        // If server fails, try to get cached data
        try {
          final cachedTypes = await localDataSource.getCachedUnitTypes(
            propertyTypeId: propertyTypeId,
          );
          return Right(cachedTypes.map((model) => model.toEntity()).toList());
        } catch (cacheError) {
          return ErrorHandler.handle(e);
        }
      }
    } else {
      // No network, get cached data
      try {
        final cachedTypes = await localDataSource.getCachedUnitTypes(
          propertyTypeId: propertyTypeId,
        );
        return Right(cachedTypes.map((model) => model.toEntity()).toList());
      } catch (e) {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة'));
      }
    }
  }
}