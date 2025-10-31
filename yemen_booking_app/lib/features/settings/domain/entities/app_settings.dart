import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String preferredLanguage;
  final String preferredCurrency;
  final String timeZone;
  final bool darkMode;
  final NotificationSettings notificationSettings;
  final Map<String, dynamic> additionalSettings;
  final DateTime? lastUpdated;

  const AppSettings({
    this.preferredLanguage = 'ar',
    this.preferredCurrency = 'YER',
    this.timeZone = 'Asia/Aden',
    this.darkMode = false,
    this.notificationSettings = const NotificationSettings(),
    this.additionalSettings = const {},
    this.lastUpdated,
  });

  AppSettings copyWith({
    String? preferredLanguage,
    String? preferredCurrency,
    String? timeZone,
    bool? darkMode,
    NotificationSettings? notificationSettings,
    Map<String, dynamic>? additionalSettings,
    DateTime? lastUpdated,
  }) {
    return AppSettings(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      timeZone: timeZone ?? this.timeZone,
      darkMode: darkMode ?? this.darkMode,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      additionalSettings: additionalSettings ?? this.additionalSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        preferredLanguage,
        preferredCurrency,
        timeZone,
        darkMode,
        notificationSettings,
        additionalSettings,
        lastUpdated,
      ];
}

class NotificationSettings extends Equatable {
  final bool bookingNotifications;
  final bool promotionalNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String notificationTone;
  final Map<String, bool> categoryPreferences;

  const NotificationSettings({
    this.bookingNotifications = true,
    this.promotionalNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.pushNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationTone = 'default',
    this.categoryPreferences = const {},
  });

  NotificationSettings copyWith({
    bool? bookingNotifications,
    bool? promotionalNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? notificationTone,
    Map<String, bool>? categoryPreferences,
  }) {
    return NotificationSettings(
      bookingNotifications: bookingNotifications ?? this.bookingNotifications,
      promotionalNotifications: promotionalNotifications ?? this.promotionalNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationTone: notificationTone ?? this.notificationTone,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
    );
  }

  @override
  List<Object?> get props => [
        bookingNotifications,
        promotionalNotifications,
        emailNotifications,
        smsNotifications,
        pushNotifications,
        soundEnabled,
        vibrationEnabled,
        notificationTone,
        categoryPreferences,
      ];
}