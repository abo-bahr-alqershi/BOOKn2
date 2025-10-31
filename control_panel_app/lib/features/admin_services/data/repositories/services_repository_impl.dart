// Removed wrong import to avoid ambiguous type
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/service_details.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/pricing_model.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_datasource.dart';

/// 📦 Repository Implementation للخدمات
class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remoteDataSource;

  ServicesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> createService({
    required String propertyId,
    required String name,
    required Money price,
    required PricingModel pricingModel,
    required String icon,
    String? description,
  }) async {
    try {
      final result = await remoteDataSource.createService(
        propertyId: propertyId,
        name: name,
        price: price,
        pricingModel: pricingModel,
        icon: icon,
        description: description,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateService({
    required String serviceId,
    String? name,
    Money? price,
    PricingModel? pricingModel,
    String? icon,
    String? description,
  }) async {
    try {
      final result = await remoteDataSource.updateService(
        serviceId: serviceId,
        name: name,
        price: price,
        pricingModel: pricingModel,
        icon: icon,
        description: description,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteService(String serviceId) async {
    try {
      final result = await remoteDataSource.deleteService(serviceId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Service>>> getServicesByProperty(
      String propertyId) async {
    try {
      final models = await remoteDataSource.getServicesByProperty(propertyId);
      final services = models.map((model) => model.toEntity()).toList();
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceDetails>> getServiceDetails(
      String serviceId) async {
    try {
      final model = await remoteDataSource.getServiceDetails(serviceId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Service>>> getServicesByType({
    required String serviceType,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final result = await remoteDataSource.getServicesByType(
        serviceType: serviceType,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      
      final services = result.items.map((model) => model.toEntity()).toList();
      
      return Right(PaginatedResult<Service>(
        items: services,
        totalCount: result.totalCount,
        pageNumber: result.pageNumber,
        pageSize: result.pageSize,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}