import '../../domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    super.preferredLanguage,
    super.preferredCurrency,
    super.timeZone,
    super.darkMode,
    super.notificationSettings,
    super.additionalSettings,
    super.lastUpdated,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      preferredLanguage: json['preferredLanguage'] ?? 'ar',
      preferredCurrency: json['preferredCurrency'] ?? 'YER',
      timeZone: json['timeZone'] ?? 'Asia/Aden',
      darkMode: json['darkMode'] ?? false,
      notificationSettings: json['notificationSettings'] != null
          ? NotificationSettingsModel.fromJson(json['notificationSettings'])
          : const NotificationSettings(),
      additionalSettings: json['additionalSettings'] ?? {},
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredLanguage': preferredLanguage,
      'preferredCurrency': preferredCurrency,
      'timeZone': timeZone,
      'darkMode': darkMode,
      'notificationSettings': (notificationSettings as NotificationSettingsModel).toJson(),
      'additionalSettings': additionalSettings,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      preferredLanguage: settings.preferredLanguage,
      preferredCurrency: settings.preferredCurrency,
      timeZone: settings.timeZone,
      darkMode: settings.darkMode,
      notificationSettings: settings.notificationSettings,
      additionalSettings: settings.additionalSettings,
      lastUpdated: settings.lastUpdated,
    );
  }
}

class NotificationSettingsModel extends NotificationSettings {
  const NotificationSettingsModel({
    super.bookingNotifications,
    super.promotionalNotifications,
    super.emailNotifications,
    super.smsNotifications,
    super.pushNotifications,
    super.soundEnabled,
    super.vibrationEnabled,
    super.notificationTone,
    super.categoryPreferences,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      bookingNotifications: json['bookingNotifications'] ?? true,
      promotionalNotifications: json['promotionalNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      pushNotifications: json['pushNotifications'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      notificationTone: json['notificationTone'] ?? 'default',
      categoryPreferences: Map<String, bool>.from(json['categoryPreferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingNotifications': bookingNotifications,
      'promotionalNotifications': promotionalNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'pushNotifications': pushNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'notificationTone': notificationTone,
      'categoryPreferences': categoryPreferences,
    };
  }
}