// lib/features/admin_properties/data/repositories/policies_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/network/network_info.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../domain/entities/policy.dart';
import '../../domain/repositories/policies_repository.dart';
import '../datasources/policies_remote_datasource.dart';

class PoliciesRepositoryImpl implements PoliciesRepository {
  final PoliciesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  
  PoliciesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, List<Policy>>> getPropertyPolicies(String propertyId) async {
    if (await networkInfo.isConnected) {
      try {
        final policies = await remoteDataSource.getPropertyPolicies(propertyId);
        return Right(policies);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, Policy>> getPolicyById(String policyId) async {
    if (await networkInfo.isConnected) {
      try {
        final policy = await remoteDataSource.getPolicyById(policyId);
        return Right(policy);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, String>> createPolicy(Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final id = await remoteDataSource.createPolicy(data);
        return Right(id);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> updatePolicy(String policyId, Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.updatePolicy(policyId, data);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> deletePolicy(String policyId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deletePolicy(policyId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, PaginatedResult<Policy>>> getPoliciesByType({
    required String policyType,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPoliciesByType(
          policyType: policyType,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        return Right(result as PaginatedResult<Policy>);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
}