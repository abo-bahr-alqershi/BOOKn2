import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object> get props => [settings];
}

class SettingsUpdating extends SettingsState {
  final AppSettings currentSettings;

  const SettingsUpdating(this.currentSettings);

  @override
  List<Object> get props => [currentSettings];
}

class SettingsUpdated extends SettingsState {
  final AppSettings settings;
  final String message;

  const SettingsUpdated(this.settings, {this.message = 'تم التحديث بنجاح'});

  @override
  List<Object> get props => [settings, message];
}

class SettingsError extends SettingsState {
  final String message;
  final AppSettings? lastKnownSettings;

  const SettingsError(this.message, {this.lastKnownSettings});

  @override
  List<Object?> get props => [message, lastKnownSettings];
}

class SettingsSyncing extends SettingsState {
  final AppSettings currentSettings;

  const SettingsSyncing(this.currentSettings);

  @override
  List<Object> get props => [currentSettings];
}

class SettingsSynced extends SettingsState {
  final AppSettings settings;

  const SettingsSynced(this.settings);

  @override
  List<Object> get props => [settings];
}