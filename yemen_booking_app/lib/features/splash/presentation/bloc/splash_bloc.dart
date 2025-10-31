import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yemen_booking_app/features/home/domain/usecases/get_property_types_usecase.dart';
import 'package:yemen_booking_app/features/reference/domain/usecases/get_cities_usecase.dart';
import 'package:yemen_booking_app/features/reference/domain/usecases/get_currencies_usecase.dart';
import 'package:yemen_booking_app/services/data_sync_service.dart';
import '../../../../core/usecases/usecase.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final DataSyncService dataSyncService;
  final GetPropertyTypesUseCase getPropertyTypesUseCase;
  final GetCitiesUseCase getCitiesUseCase;
  final GetCurrenciesUseCase getCurrenciesUseCase;

  SplashBloc({
    required this.dataSyncService,
    required this.getPropertyTypesUseCase,
    required this.getCitiesUseCase,
    required this.getCurrenciesUseCase,
  }) : super(const SplashInitial()) {
    on<PreloadAppDataEvent>(_onPreload);
  }

  Future<void> _onPreload(PreloadAppDataEvent event, Emitter<SplashState> emit) async {
    emit(const SplashLoading(progress: 0.05));
    try {
      // Run operations in parallel where possible
      final futures = <Future<dynamic>>[
        dataSyncService.syncAllData(), // property types, unit types, dynamic fields
        getPropertyTypesUseCase(NoParams()), // ensure domain side cached too
        getCitiesUseCase(NoParams()),
        getCurrenciesUseCase(NoParams()),
      ];

      double completed = 0;
      final total = futures.length.toDouble();

      for (final f in futures) {
        await f;
        completed += 1;
        emit(SplashLoading(progress: (completed / total).clamp(0, 1)));
      }

      // Collect stats
      final stats = dataSyncService.getDataStats();
      emit(SplashLoaded(stats: stats));
    } catch (e) {
      emit(SplashError(e.toString()));
    }
  }
}

