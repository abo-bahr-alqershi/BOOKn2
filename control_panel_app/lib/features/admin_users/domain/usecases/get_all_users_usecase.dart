import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/users_repository.dart';

class GetAllUsersUseCase implements UseCase<PaginatedResult<User>, GetAllUsersParams> {
  final UsersRepository repository;

  GetAllUsersUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<User>>> call(GetAllUsersParams params) {
    return repository.getAllUsers(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      searchTerm: params.searchTerm,
      sortBy: params.sortBy,
      isAscending: params.isAscending,
      roleId: params.roleId,
      isActive: params.isActive,
      createdAfter: params.createdAfter,
      createdBefore: params.createdBefore,
      lastLoginAfter: params.lastLoginAfter,
      loyaltyTier: params.loyaltyTier,
      minTotalSpent: params.minTotalSpent,
    );
  }
}

class GetAllUsersParams extends Equatable {
  final int? pageNumber;
  final int? pageSize;
  final String? searchTerm;
  final String? sortBy;
  final bool? isAscending;
  final String? roleId;
  final bool? isActive;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? lastLoginAfter;
  final String? loyaltyTier;
  final double? minTotalSpent;

  const GetAllUsersParams({
    this.pageNumber,
    this.pageSize,
    this.searchTerm,
    this.sortBy,
    this.isAscending,
    this.roleId,
    this.isActive,
    this.createdAfter,
    this.createdBefore,
    this.lastLoginAfter,
    this.loyaltyTier,
    this.minTotalSpent,
  });

  @override
  List<Object?> get props => [
        pageNumber,
        pageSize,
        searchTerm,
        sortBy,
        isAscending,
        roleId,
        isActive,
        createdAfter,
        createdBefore,
        lastLoginAfter,
        loyaltyTier,
        minTotalSpent,
      ];
}