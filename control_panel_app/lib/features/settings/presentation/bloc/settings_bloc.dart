import 'package:bookn_cp_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../../../services/biometric_auth_service.dart';
import '../../../../services/local_storage_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/update_language_usecase.dart';
import '../../domain/usecases/update_theme_usecase.dart';
import '../../domain/usecases/update_biometric_usecase.dart';
import '../../domain/usecases/update_notification_settings_usecase.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettingsUseCase getSettingsUseCase;
  final UpdateLanguageUseCase updateLanguageUseCase;
  final UpdateThemeUseCase updateThemeUseCase;
  final UpdateBiometricUseCase? updateBiometricUseCase;
  final UpdateNotificationSettingsUseCase updateNotificationSettingsUseCase;
  final AuthLocalDataSource localDataSource;
  final BiometricAuthService biometricAuthService;

  AppSettings? _currentSettings;

  SettingsBloc({
    required this.getSettingsUseCase,
    required this.updateLanguageUseCase,
    required this.updateThemeUseCase,
    required this.updateNotificationSettingsUseCase,
    required this.localDataSource,
    required this.biometricAuthService,
    this.updateBiometricUseCase,
  }) : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateLanguageEvent>(_onUpdateLanguage);
    on<UpdateThemeEvent>(_onUpdateTheme);
    on<UpdateNotificationSettingsEvent>(_onUpdateNotificationSettings);
    on<UpdateBiometricEvent>(_onUpdateBiometric);
    on<UpdateCurrencyEvent>(_onUpdateCurrency);
    on<UpdateTimeZoneEvent>(_onUpdateTimeZone);
    on<ResetSettingsEvent>(_onResetSettings);
    on<SyncSettingsEvent>(_onSyncSettings);
    on<AcceptPrivacyPolicyEvent>(_onAcceptPrivacyPolicy);

    // Load settings on initialization
    add(LoadSettingsEvent());
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    final result = await getSettingsUseCase(NoParams());

    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (settings) {
        _currentSettings = settings;
        emit(SettingsLoaded(settings));
      },
    );
  }

  Future<void> _onUpdateLanguage(
    UpdateLanguageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentSettings != null) {
      emit(SettingsUpdating(_currentSettings!));

      final result = await updateLanguageUseCase(
        UpdateLanguageParams(languageCode: event.languageCode),
      );

      await result.fold(
        (failure) async => emit(
          SettingsError(failure.message, lastKnownSettings: _currentSettings),
        ),
        (success) async {
          _currentSettings = _currentSettings!.copyWith(
            preferredLanguage: event.languageCode,
          );
          emit(SettingsUpdated(
            _currentSettings!,
            message: 'تم تغيير اللغة بنجاح',
          ));
          // Reload to ensure consistency
          add(LoadSettingsEvent());
        },
      );
    }
  }

  Future<void> _onUpdateTheme(
    UpdateThemeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentSettings != null) {
      emit(SettingsUpdating(_currentSettings!));

      final result = await updateThemeUseCase(
        UpdateThemeParams(isDarkMode: event.isDarkMode),
      );

      await result.fold(
        (failure) async => emit(
          SettingsError(failure.message, lastKnownSettings: _currentSettings),
        ),
        (success) async {
          _currentSettings = _currentSettings!.copyWith(
            darkMode: event.isDarkMode,
          );
          emit(SettingsUpdated(
            _currentSettings!,
            message: event.isDarkMode
                ? 'تم تفعيل الوضع الليلي'
                : 'تم تفعيل الوضع النهاري',
          ));
          // Reload to ensure consistency
          add(LoadSettingsEvent());
        },
      );
    }
  }

  Future<void> _onUpdateBiometric(
    UpdateBiometricEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentSettings != null) {
      emit(SettingsUpdating(_currentSettings!));

      if (updateBiometricUseCase == null) {
        // fallback: update locally via localDataSource if DI not available
        try {
          await localDataSource.saveData('biometric_enabled', event.enabled);
          _currentSettings = _currentSettings!.copyWith(
            biometricEnabled: event.enabled,
            additionalSettings: {
              ..._currentSettings!.additionalSettings,
              'biometricEnabled': event.enabled,
            },
          );
          await _syncBiometricStorage(event.enabled);
          emit(SettingsUpdated(_currentSettings!,
              message: event.enabled
                  ? 'تم تفعيل تسجيل الدخول بالبصمة'
                  : 'تم إيقاف تسجيل الدخول بالبصمة'));
          add(LoadSettingsEvent());
        } catch (e) {
          emit(SettingsError('فشل تحديث البصمة',
              lastKnownSettings: _currentSettings));
        }
        return;
      }

      final result = await updateBiometricUseCase!(
        UpdateBiometricParams(enabled: event.enabled),
      );

      await result.fold(
        (failure) async => emit(
          SettingsError(failure.message, lastKnownSettings: _currentSettings),
        ),
        (success) async {
          _currentSettings = _currentSettings!.copyWith(
            biometricEnabled: event.enabled,
            additionalSettings: {
              ..._currentSettings!.additionalSettings,
              'biometricEnabled': event.enabled,
            },
          );
          await _syncBiometricStorage(event.enabled);
          emit(SettingsUpdated(
            _currentSettings!,
            message: event.enabled
                ? 'تم تفعيل تسجيل الدخول بالبصمة'
                : 'تم إيقاف تسجيل الدخول بالبصمة',
          ));
          add(LoadSettingsEvent());
        },
      );
    }
  }

  Future<void> _onUpdateNotificationSettings(
    UpdateNotificationSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentSettings != null) {
      emit(SettingsUpdating(_currentSettings!));

      final result = await updateNotificationSettingsUseCase(
        UpdateNotificationSettingsParams(settings: event.settings),
      );

      await result.fold(
        (failure) async => emit(
          SettingsError(failure.message, lastKnownSettings: _currentSettings),
        ),
        (success) async {
          _currentSettings = _currentSettings!.copyWith(
            notificationSettings: event.settings,
          );
          emit(SettingsUpdated(
            _currentSettings!,
            message: 'تم تحديث إعدادات الإشعارات',
          ));
          // Reload to ensure consistency
          add(LoadSettingsEvent());
        },
      );
    }
  }

  Future<void> _onUpdateCurrency(
    UpdateCurrencyEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentSettings != null) {
      emit(SettingsUpdating(_currentSettings!));

      // Since we don't have a specific use case for currency,
      // we'll update the settings directly
      _currentSettings = _currentSettings!.copyWith(
        preferredCurrency: event.currencyCode,
      );

      emit(SettingsUpdated(
        _currentSettings!,
        message: 'تم تغيير العملة بنجاح',
      ));
    }
  }

  Future<void> _onUpdateTimeZone(
    UpdateTimeZoneEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentSettings != null) {
      emit(SettingsUpdating(_currentSettings!));

      _currentSettings = _currentSettings!.copyWith(
        timeZone: event.timeZone,
      );

      emit(SettingsUpdated(
        _currentSettings!,
        message: 'تم تغيير المنطقة الزمنية',
      ));
    }
  }

  Future<void> _onResetSettings(
    ResetSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    // Reset to default settings
    _currentSettings = const AppSettings();

    emit(SettingsUpdated(
      _currentSettings!,
      message: 'تم إعادة الإعدادات إلى الوضع الافتراضي',
    ));

    // Reload settings
    add(LoadSettingsEvent());
  }

  Future<void> _onSyncSettings(
    SyncSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentSettings != null) {
      emit(SettingsSyncing(_currentSettings!));

      // Simulate sync delay
      await Future.delayed(const Duration(seconds: 2));

      emit(SettingsSynced(_currentSettings!));

      // Reload settings after sync
      add(LoadSettingsEvent());
    }
  }

  Future<void> _onAcceptPrivacyPolicy(
    AcceptPrivacyPolicyEvent event,
    Emitter<SettingsState> emit,
  ) async {
    // Save that user accepted privacy policy
    await localDataSource.saveData('privacy_policy_accepted', true);
    await localDataSource.saveData(
        'privacy_policy_accepted_date', DateTime.now().toIso8601String());

    // Optionally update settings
    if (_currentSettings != null) {
      final updatedSettings = _currentSettings!.copyWith(
        additionalSettings: {
          ..._currentSettings!.additionalSettings,
          'privacyPolicyAccepted': true,
          'privacyPolicyAcceptedDate': DateTime.now().toIso8601String(),
        },
      );
      _currentSettings = updatedSettings;
      emit(SettingsUpdated(updatedSettings, message: 'تم قبول سياسة الخصوصية'));
    }
  }

  Future<void> _syncBiometricStorage(bool enabled) async {
    if (enabled) {
      String? refreshToken;
      try {
        refreshToken = await localDataSource.getCachedRefreshToken();
      } catch (_) {}

      if (refreshToken == null || refreshToken.isEmpty) {
        final localStorage = sl<LocalStorageService>();
        final stored = localStorage.getData(StorageConstants.refreshToken);
        if (stored is String && stored.isNotEmpty) {
          refreshToken = stored;
        }
      }

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await biometricAuthService.saveRefreshTokenSecurely(refreshToken);
        } catch (_) {}
      }
    } else {
      try {
        await biometricAuthService.clearSecureRefreshToken();
      } catch (_) {}
    }
  }
}
