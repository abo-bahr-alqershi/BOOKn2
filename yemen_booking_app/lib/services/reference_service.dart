import 'package:get_it/get_it.dart';
import 'package:yemen_booking_app/features/reference/data/datasources/reference_local_datasource.dart';
import 'package:yemen_booking_app/features/reference/domain/entities/city.dart';
import 'package:yemen_booking_app/features/reference/domain/entities/currency.dart';

class ReferenceService {
  final ReferenceLocalDataSource _local;

  ReferenceService._(this._local);

  static ReferenceService get instance => ReferenceService._(GetIt.instance<ReferenceLocalDataSource>());

  List<City> getCachedCities() => _local.getCachedCities().map((e) => e.toEntity()).toList();
  List<Currency> getCachedCurrencies() => _local.getCachedCurrencies().map((e) => e.toEntity()).toList();
}

