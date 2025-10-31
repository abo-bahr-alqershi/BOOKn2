import 'package:dartz/dartz.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/app_settings_model.dart';
import '../../../../injection_container.dart' as di;
import '../../../../core/constants/storage_constants.dart';
import '../../../../services/local_storage_service.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../../core/network/api_client.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final settings = await localDataSource.getSettings();
      return Right(settings);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> updateLanguage(String languageCode) async {
    try {
      final result = await localDataSource.updateLanguage(languageCode);
      return Right(result);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> updateTheme(bool isDarkMode) async {
    try {
      final result = await localDataSource.updateTheme(isDarkMode);
      return Right(result);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> updateBiometric(bool enabled) async {
    try {
      final result = await localDataSource.updateBiometric(enabled);
      // Sync to backend AdditionalSettings via /api/client/settings
      try {
        final api = di.sl<ApiClient>();
        final local = di.sl<LocalStorageService>();
        final auth = di.sl<AuthLocalDataSource>();
        final userId = (await auth.getCachedUser())?.userId ?? (local.getData(StorageConstants.userId)?.toString() ?? '');
        
        if (userId.isNotEmpty) {
          // Get current settings to send complete data
          final currentSettings = await localDataSource.getCachedSettings();
          
          // Prepare notification settings data
          final notificationSettingsData = currentSettings != null
              ? {
                  'bookingNotifications': currentSettings.notificationSettings.bookingNotifications,
                  'promotionalNotifications': currentSettings.notificationSettings.promotionalNotifications,
                  'emailNotifications': currentSettings.notificationSettings.emailNotifications,
                  'smsNotifications': currentSettings.notificationSettings.smsNotifications,
                  'pushNotifications': currentSettings.notificationSettings.pushNotifications,
                }
              : {
                  'bookingNotifications': true,
                  'promotionalNotifications': true,
                  'emailNotifications': true,
                  'smsNotifications': false,
                  'pushNotifications': true,
                };
          
          // Send complete settings with updated biometric value
          await api.put('/api/client/settings', data: {
            'userId': userId,
            'preferredLanguage': currentSettings?.preferredLanguage ?? 'ar',
            'preferredCurrency': currentSettings?.preferredCurrency ?? 'YER',
            'timeZone': currentSettings?.timeZone ?? 'Asia/Aden',
            'darkMode': currentSettings?.darkMode ?? false,
            'notificationSettings': notificationSettingsData,
            'additionalSettings': {
              ...?currentSettings?.additionalSettings,
              'biometricEnabled': enabled,
            },
          });
        }
      } catch (_) {
        // Silently fail if backend sync fails - local update is already done
      }
      return Right(result);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    try {
      final notificationModel = NotificationSettingsModel(
        bookingNotifications: settings.bookingNotifications,
        promotionalNotifications: settings.promotionalNotifications,
        emailNotifications: settings.emailNotifications,
        smsNotifications: settings.smsNotifications,
        pushNotifications: settings.pushNotifications,
        soundEnabled: settings.soundEnabled,
        vibrationEnabled: settings.vibrationEnabled,
        notificationTone: settings.notificationTone,
        categoryPreferences: settings.categoryPreferences,
      );
      
      final result = await localDataSource.updateNotificationSettings(notificationModel);
      return Right(result);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> updateCurrency(String currencyCode) async {
    try {
      final result = await localDataSource.updateCurrency(currencyCode);
      return Right(result);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> updateTimeZone(String timeZone) async {
    try {
      final result = await localDataSource.updateTimeZone(timeZone);
      return Right(result);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> saveSettings(AppSettings settings) async {
    try {
      final settingsModel = AppSettingsModel.fromEntity(settings);
      final result = await localDataSource.saveSettings(settingsModel);
      return Right(result);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> resetSettings() async {
    try {
      final result = await localDataSource.clearSettings();
      return Right(result);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }

  @override
  Future<Either<Failure, bool>> syncSettingsWithServer() async {
    try {
      // TODO: Implement server sync when API is ready
      // For now, just return success
      return const Right(true);
    } catch (e) {
      return ErrorHandler.handle(e);
    }
  }
}