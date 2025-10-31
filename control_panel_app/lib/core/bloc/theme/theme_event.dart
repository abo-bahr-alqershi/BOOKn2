// lib/core/presentation/bloc/theme/theme_event.dart

import 'package:flutter/material.dart';

abstract class ThemeEvent {
  const ThemeEvent();
}

class LoadThemeEvent extends ThemeEvent {
  const LoadThemeEvent();
}

class ToggleThemeEvent extends ThemeEvent {
  const ToggleThemeEvent();
}

class SetThemeEvent extends ThemeEvent {
  final ThemeMode themeMode;
  
  const SetThemeEvent({required this.themeMode});
}

class SetSystemThemeEvent extends ThemeEvent {
  const SetSystemThemeEvent();
}