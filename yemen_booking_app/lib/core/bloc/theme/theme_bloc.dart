// lib/core/presentation/bloc/theme/theme_bloc.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'app_theme_mode';
  static const String _themeModeLight = 'light';
  static const String _themeModeDark = 'dark';
  static const String _themeModeSystem = 'system';
  
  final SharedPreferences _prefs;

  ThemeBloc({required SharedPreferences prefs})
      : _prefs = prefs,
        super(ThemeState.initial()) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ToggleThemeEvent>(_onToggleTheme);
    on<SetThemeEvent>(_onSetTheme);
    on<SetSystemThemeEvent>(_onSetSystemTheme);
    
    // Load saved theme on initialization
    add(const LoadThemeEvent());
  }

  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final savedTheme = _prefs.getString(_themeKey);
      
      ThemeMode themeMode;
      switch (savedTheme) {
        case _themeModeLight:
          themeMode = ThemeMode.light;
          break;
        case _themeModeDark:
          themeMode = ThemeMode.dark;
          break;
        case _themeModeSystem:
          themeMode = ThemeMode.system;
          break;
        default:
          themeMode = ThemeMode.dark; // Default to dark
      }
      
      emit(ThemeState(
        themeMode: themeMode,
        isLoading: false,
      ));
    } catch (e) {
      // If error, default to dark theme
      emit(const ThemeState(
        themeMode: ThemeMode.dark,
        isLoading: false,
      ));
    }
  }

  Future<void> _onToggleTheme(
    ToggleThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final newMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    
    await _saveThemeMode(newMode);
    emit(ThemeState(
      themeMode: newMode,
      isLoading: false,
    ));
  }

  Future<void> _onSetTheme(
    SetThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    await _saveThemeMode(event.themeMode);
    emit(ThemeState(
      themeMode: event.themeMode,
      isLoading: false,
    ));
  }

  Future<void> _onSetSystemTheme(
    SetSystemThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    await _saveThemeMode(ThemeMode.system);
    emit(const ThemeState(
      themeMode: ThemeMode.system,
      isLoading: false,
    ));
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = _themeModeLight;
        break;
      case ThemeMode.dark:
        value = _themeModeDark;
        break;
      case ThemeMode.system:
        value = _themeModeSystem;
        break;
    }
    await _prefs.setString(_themeKey, value);
  }
}