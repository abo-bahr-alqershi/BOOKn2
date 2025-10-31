// lib/core/presentation/bloc/theme/theme_state.dart

import 'package:flutter/material.dart';

class ThemeState {
  final ThemeMode themeMode;
  final bool isLoading;
  
  const ThemeState({
    required this.themeMode,
    this.isLoading = false,
  });
  
  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  factory ThemeState.initial() {
    return const ThemeState(
      themeMode: ThemeMode.dark,
      isLoading: true,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ThemeState &&
        other.themeMode == themeMode &&
        other.isLoading == isLoading;
  }
  
  @override
  int get hashCode => themeMode.hashCode ^ isLoading.hashCode;
}