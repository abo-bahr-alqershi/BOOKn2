import 'package:bookn_cp_app/features/reference/domain/usecases/get_cities_usecase.dart'
    as ref_cities;
import 'package:bookn_cp_app/features/reference/domain/usecases/get_currencies_usecase.dart'
    as ref_currencies;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bookn_cp_app/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:bookn_cp_app/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final LocalStorageService localStorage;
  final ref_cities.GetCitiesUseCase getCitiesUseCase;
  final ref_currencies.GetCurrenciesUseCase getCurrenciesUseCase;

  OnboardingBloc({
    required this.localStorage,
    required this.getCitiesUseCase,
    required this.getCurrenciesUseCase,
  }) : super(const OnboardingInitial()) {
    on<CheckFirstRunEvent>(_onCheckFirstRun);
    on<CompleteOnboardingEvent>(_onComplete);
  }

  Future<void> _onCheckFirstRun(
      CheckFirstRunEvent event, Emitter<OnboardingState> emit) async {
    final hasDone = localStorage.isOnboardingCompleted();
    if (hasDone) {
      emit(const OnboardingNotRequired());
      return;
    }
    // Ensure reference data exists
    await getCitiesUseCase(NoParams());
    await getCurrenciesUseCase(NoParams());
    emit(const OnboardingRequired());
  }

  Future<void> _onComplete(
      CompleteOnboardingEvent event, Emitter<OnboardingState> emit) async {
    emit(const OnboardingCompleting());

    // حفظ المدينة والعملة
    await localStorage.saveSelectedCity(event.city);
    await localStorage.saveSelectedCurrency(event.currencyCode);
    await localStorage.setOnboardingCompleted(true);

    emit(const OnboardingCompleted());
  }
}
