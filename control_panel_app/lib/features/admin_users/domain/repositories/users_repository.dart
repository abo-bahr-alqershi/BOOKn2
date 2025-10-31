import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/user.dart';
import '../entities/user_details.dart';
import '../entities/user_lifetime_stats.dart';

abstract class UsersRepository {
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
  });

  Future<Either<Failure, UserDetails>> getUserDetails(String userId);

  Future<Either<Failure, String>> createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? profileImage,
  });

  Future<Either<Failure, bool>> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
  });

  Future<Either<Failure, bool>> activateUser(String userId);

  Future<Either<Failure, bool>> deactivateUser(String userId);

  Future<Either<Failure, bool>> assignRole({
    required String userId,
    required String roleId,
  });

  Future<Either<Failure, UserLifetimeStats>> getUserLifetimeStats(String userId);
}