import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/service.dart';
import '../entities/service_details.dart';
import '../entities/money.dart';
import '../entities/pricing_model.dart';

/// 📚 Repository Interface للخدمات
abstract class ServicesRepository {
  /// إنشاء خدمة جديدة
  Future<Either<Failure, String>> createService({
    required String propertyId,
    required String name,
    required Money price,
    required PricingModel pricingModel,
    required String icon,
    String? description,
  });

  /// تحديث خدمة
  Future<Either<Failure, bool>> updateService({
    required String serviceId,
    String? name,
    Money? price,
    PricingModel? pricingModel,
    String? icon,
    String? description,
  });

  /// حذف خدمة
  Future<Either<Failure, bool>> deleteService(String serviceId);

  /// جلب خدمات عقار معين
  Future<Either<Failure, List<Service>>> getServicesByProperty(String propertyId);

  /// جلب تفاصيل خدمة
  Future<Either<Failure, ServiceDetails>> getServiceDetails(String serviceId);

  /// جلب الخدمات حسب النوع
  Future<Either<Failure, PaginatedResult<Service>>> getServicesByType({
    required String serviceType,
    int? pageNumber,
    int? pageSize,
  });
}