import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/helpers_repository.dart';
import '../datasources/helpers_remote_datasource.dart';

class HelpersRepositoryImpl implements HelpersRepository {
  final HelpersRemoteDataSource remoteDataSource;

  HelpersRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResult<SearchResult>>> searchUsers({
    String? searchTerm,
    String? role,
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.searchUsers(
        searchTerm: searchTerm,
        role: role,
        isActive: isActive,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<SearchResult>>> searchProperties({
    String? searchTerm,
    String? typeId,
    String? city,
    bool? isApproved,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.searchProperties(
        searchTerm: searchTerm,
        typeId: typeId,
        city: city,
        isApproved: isApproved,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<SearchResult>>> searchUnits({
    String? searchTerm,
    String? propertyId,
    String? unitTypeId,
    bool? isAvailable,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.searchUnits(
        searchTerm: searchTerm,
        propertyId: propertyId,
        unitTypeId: unitTypeId,
        isAvailable: isAvailable,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<SearchResult>>> searchCities({
    String? searchTerm,
    String? country,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.searchCities(
        searchTerm: searchTerm,
        country: country,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<SearchResult>>> searchBookings({
    String? searchTerm,
    String? userId,
    String? unitId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.searchBookings(
        searchTerm: searchTerm,
        userId: userId,
        unitId: unitId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}