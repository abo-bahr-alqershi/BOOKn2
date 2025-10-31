import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class UpdateLanguageEvent extends SettingsEvent {
  final String languageCode;

  const UpdateLanguageEvent(this.languageCode);

  @override
  List<Object> get props => [languageCode];
}

class UpdateThemeEvent extends SettingsEvent {
  final bool isDarkMode;

  const UpdateThemeEvent(this.isDarkMode);

  @override
  List<Object> get props => [isDarkMode];
}

class UpdateNotificationSettingsEvent extends SettingsEvent {
  final NotificationSettings settings;

  const UpdateNotificationSettingsEvent(this.settings);

  @override
  List<Object> get props => [settings];
}

class UpdateCurrencyEvent extends SettingsEvent {
  final String currencyCode;

  const UpdateCurrencyEvent(this.currencyCode);

  @override
  List<Object> get props => [currencyCode];
}

class UpdateTimeZoneEvent extends SettingsEvent {
  final String timeZone;

  const UpdateTimeZoneEvent(this.timeZone);

  @override
  List<Object> get props => [timeZone];
}

class ResetSettingsEvent extends SettingsEvent {}

class SyncSettingsEvent extends SettingsEvent {}

class AcceptPrivacyPolicyEvent extends SettingsEvent {
  const AcceptPrivacyPolicyEvent();
  
  @override
  List<Object?> get props => [];
}