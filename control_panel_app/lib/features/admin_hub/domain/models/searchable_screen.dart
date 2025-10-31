// lib/features/admin_hub/domain/models/searchable_screen.dart

import 'package:flutter/material.dart';

class SearchableScreen {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String path;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> searchKeywords;
  final String category;
  final int visitCount;
  final DateTime? lastVisitedAt;
  final bool isPinned;
  final bool adminOnly;
  final bool visibleForOwner;

  SearchableScreen({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.path,
    required this.icon,
    required this.gradientColors,
    required this.searchKeywords,
    required this.category,
    this.visitCount = 0,
    this.lastVisitedAt,
    this.isPinned = false,
    this.adminOnly = false,
    this.visibleForOwner = false,
  });

  SearchableScreen copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? descriptionAr,
    String? descriptionEn,
    String? path,
    IconData? icon,
    List<Color>? gradientColors,
    List<String>? searchKeywords,
    String? category,
    int? visitCount,
    DateTime? lastVisitedAt,
    bool? isPinned,
    bool? adminOnly,
    bool? visibleForOwner,
  }) {
    return SearchableScreen(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      path: path ?? this.path,
      icon: icon ?? this.icon,
      gradientColors: gradientColors ?? this.gradientColors,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      category: category ?? this.category,
      visitCount: visitCount ?? this.visitCount,
      lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      isPinned: isPinned ?? this.isPinned,
      adminOnly: adminOnly ?? this.adminOnly,
      visibleForOwner: visibleForOwner ?? this.visibleForOwner,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titleAr': titleAr,
    'titleEn': titleEn,
    'descriptionAr': descriptionAr,
    'descriptionEn': descriptionEn,
    'path': path,
    'icon': icon.codePoint,
    'gradientColors': gradientColors.map((c) => c.value).toList(),
    'searchKeywords': searchKeywords,
    'category': category,
    'visitCount': visitCount,
    'lastVisitedAt': lastVisitedAt?.toIso8601String(),
    'isPinned': isPinned,
    'adminOnly': adminOnly,
    'visibleForOwner': visibleForOwner,
  };

  factory SearchableScreen.fromJson(Map<String, dynamic> json) => SearchableScreen(
    id: json['id'],
    titleAr: json['titleAr'],
    titleEn: json['titleEn'],
    descriptionAr: json['descriptionAr'],
    descriptionEn: json['descriptionEn'],
    path: json['path'],
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
    gradientColors: (json['gradientColors'] as List).map((c) => Color(c)).toList(),
    searchKeywords: List<String>.from(json['searchKeywords']),
    category: json['category'],
    visitCount: json['visitCount'] ?? 0,
    lastVisitedAt: json['lastVisitedAt'] != null 
        ? DateTime.parse(json['lastVisitedAt']) 
        : null,
    isPinned: json['isPinned'] ?? false,
    adminOnly: json['adminOnly'] ?? false,
    visibleForOwner: json['visibleForOwner'] ?? false,
  );
}

class ScreenCategory {
  static const String financial = 'المالية';
  static const String bookings = 'الحجوزات';
  static const String properties = 'العقارات';
  static const String users = 'المستخدمون';
  static const String settings = 'الإعدادات';
  static const String reports = 'التقارير';
  static const String notifications = 'الإشعارات';
  static const String services = 'الخدمات';
  static const String policies = 'السياسات';
  static const String other = 'أخرى';
}
