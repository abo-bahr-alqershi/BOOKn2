import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_exceptions.dart' hide ApiException;
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_details.dart';
import '../../domain/entities/user_lifetime_stats.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_local_datasource.dart';
import '../datasources/users_remote_datasource.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;
  final UsersLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UsersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedResult<User>>> getAllUsers({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? sortBy,
    bool? isAscending,
    String? roleId,
    bool? isActive,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? lastLoginAfter,
    String? loyaltyTier,
    double? minTotalSpent,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllUsers(
          pageNumber: pageNumber,
          pageSize: pageSize,
          searchTerm: searchTerm,
          sortBy: sortBy,
          isAscending: isAscending,
          roleId: roleId,
          isActive: isActive,
          createdAfter: createdAfter,
          createdBefore: createdBefore,
          lastLoginAfter: lastLoginAfter,
          loyaltyTier: loyaltyTier,
          minTotalSpent: minTotalSpent,
        );

        // Cache first page for offline access
        if (pageNumber == 1 || pageNumber == null) {
          await localDataSource.cacheUsers(result.items);
        }

        return Right(PaginatedResult<User>(
          items: result.items,
          totalCount: result.totalCount,
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
        ));
      } on ApiException catch (e) {
        return Left(ServerFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedUsers = await localDataSource.getCachedUsers();
        return Right(PaginatedResult<User>(
          items: cachedUsers,
          totalCount: cachedUsers.length,
          pageNumber: 1,
          pageSize: cachedUsers.length,
        ));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, UserDetails>> getUserDetails(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final userDetails = await remoteDataSource.getUserDetails(userId);
      return Right(userDetails);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? profileImage,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final userId = await remoteDataSource.createUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        profileImage: profileImage,
      );
      return Right(userId);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final success = await remoteDataSource.updateUser(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        profileImage: profileImage,
      );
      return Right(success);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> activateUser(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final success = await remoteDataSource.activateUser(userId);
      return Right(success);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> deactivateUser(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final success = await remoteDataSource.deactivateUser(userId);
      return Right(success);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> assignRole({
    required String userId,
    required String roleId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final success = await remoteDataSource.assignRole(
        userId: userId,
        roleId: roleId,
      );
      return Right(success);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserLifetimeStats>> getUserLifetimeStats(
      String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final stats = await remoteDataSource.getUserLifetimeStats(userId);
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
