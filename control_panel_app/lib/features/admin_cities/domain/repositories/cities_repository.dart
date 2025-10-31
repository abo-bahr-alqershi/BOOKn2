import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../entities/city.dart';

/// 📍 Cities Repository Interface
abstract class CitiesRepository {
  /// الحصول على جميع المدن
  Future<Either<Failure, List<City>>> getCities({
    int? page,
    int? limit,
    String? search,
    String? country,
    bool? isActive,
  });

  /// حفظ قائمة المدن (إضافة أو تحديث)
  Future<Either<Failure, bool>> saveCities(List<City> cities);

  /// إضافة مدينة جديدة
  Future<Either<Failure, City>> createCity(City city);

  /// تحديث مدينة موجودة
  Future<Either<Failure, City>> updateCity(String oldName, City city);

  /// حذف مدينة
  Future<Either<Failure, bool>> deleteCity(String name);

  /// البحث في المدن
  Future<Either<Failure, List<City>>> searchCities(String query);

  /// الحصول على إحصائيات المدن مع دعم اتجاهات عبر نافذة زمنية
  Future<Either<Failure, Map<String, dynamic>>> getCitiesStatistics({DateTime? startDate, DateTime? endDate});

  /// رفع صورة للمدينة مع دعم التقدم
  Future<Either<Failure, String>> uploadCityImage(String cityName, String imagePath, {ProgressCallback? onSendProgress});

  /// حذف صورة من المدينة
  Future<Either<Failure, bool>> deleteCityImage(String imageUrl);
}