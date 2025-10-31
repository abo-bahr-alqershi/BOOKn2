// lib/features/admin_hub/data/services/screen_search_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/searchable_screen.dart';
import '../../../../core/theme/app_theme.dart';

class ScreenSearchService {
  static const String _searchHistoryKey = 'screen_search_history';
  static const String _visitHistoryKey = 'screen_visit_history';
  static const String _pinnedScreensKey = 'pinned_screens';
  static const int _maxSearchHistory = 20;
  static const int _maxSuggestions = 10;

  final SharedPreferences _prefs;

  ScreenSearchService(this._prefs);

  // قائمة الشاشات المتاحة (بدون بارامترات)
  final List<SearchableScreen> _allScreens = [
    // المالية
    SearchableScreen(
      id: 'financial_dashboard',
      titleAr: 'لوحة المالية',
      titleEn: 'Financial Dashboard',
      descriptionAr: 'عرض إحصائيات مالية شاملة',
      descriptionEn: 'View comprehensive financial statistics',
      path: '/admin/financial/dashboard',
      icon: Icons.dashboard_rounded,
      gradientColors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
      searchKeywords: ['مالية', 'احصائيات', 'تقارير', 'ايرادات', 'مصروفات', 'financial', 'dashboard', 'revenue'],
      category: ScreenCategory.financial,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'financial_transactions',
      titleAr: 'المعاملات المالية',
      titleEn: 'Financial Transactions',
      descriptionAr: 'إدارة وعرض جميع المعاملات المالية',
      descriptionEn: 'Manage and view all financial transactions',
      path: '/admin/financial/transactions',
      icon: Icons.receipt_long_rounded,
      gradientColors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
      searchKeywords: ['معاملات', 'مالية', 'فواتير', 'دفعات', 'transactions', 'invoices', 'payments'],
      category: ScreenCategory.financial,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'chart_of_accounts',
      titleAr: 'دليل الحسابات',
      titleEn: 'Chart of Accounts',
      descriptionAr: 'إدارة شجرة الحسابات المالية',
      descriptionEn: 'Manage financial accounts tree',
      path: '/admin/financial/accounts',
      icon: Icons.account_tree_rounded,
      gradientColors: [AppTheme.success, AppTheme.neonGreen],
      searchKeywords: ['حسابات', 'شجرة', 'دليل', 'accounts', 'chart', 'tree'],
      category: ScreenCategory.financial,
      adminOnly: true,
    ),

    // الحجوزات
    SearchableScreen(
      id: 'bookings_list',
      titleAr: 'قائمة الحجوزات',
      titleEn: 'Bookings List',
      descriptionAr: 'عرض وإدارة جميع الحجوزات',
      descriptionEn: 'View and manage all bookings',
      path: '/admin/bookings',
      icon: Icons.calendar_month_rounded,
      gradientColors: [AppTheme.primaryCyan, AppTheme.neonBlue],
      searchKeywords: ['حجوزات', 'حجز', 'bookings', 'reservations', 'booking'],
      category: ScreenCategory.bookings,
    ),
    SearchableScreen(
      id: 'bookings_upcoming',
      titleAr: 'الحجوزات القادمة',
      titleEn: 'Upcoming Bookings',
      descriptionAr: 'عرض الحجوزات القادمة',
      descriptionEn: 'View upcoming bookings',
      path: '/admin/bookings/upcoming',
      icon: Icons.upcoming_rounded,
      gradientColors: [AppTheme.warning, AppTheme.neonPurple],
      searchKeywords: ['حجوزات', 'قادمة', 'مستقبل', 'upcoming', 'future', 'bookings'],
      category: ScreenCategory.bookings,
    ),
    SearchableScreen(
      id: 'bookings_calendar',
      titleAr: 'تقويم الحجوزات',
      titleEn: 'Bookings Calendar',
      descriptionAr: 'عرض الحجوزات في التقويم',
      descriptionEn: 'View bookings in calendar',
      path: '/admin/bookings/calendar',
      icon: Icons.calendar_view_month_rounded,
      gradientColors: [AppTheme.info, AppTheme.primaryBlue],
      searchKeywords: ['تقويم', 'رزنامة', 'calendar', 'schedule'],
      category: ScreenCategory.bookings,
    ),
    SearchableScreen(
      id: 'bookings_timeline',
      titleAr: 'جدول الحجوزات الزمني',
      titleEn: 'Bookings Timeline',
      descriptionAr: 'عرض الجدول الزمني للحجوزات',
      descriptionEn: 'View bookings timeline',
      path: '/admin/bookings/timeline',
      icon: Icons.timeline_rounded,
      gradientColors: [AppTheme.primaryViolet, AppTheme.neonGreen],
      searchKeywords: ['جدول', 'زمني', 'timeline', 'schedule'],
      category: ScreenCategory.bookings,
    ),
    SearchableScreen(
      id: 'bookings_analytics',
      titleAr: 'تحليلات الحجوزات',
      titleEn: 'Bookings Analytics',
      descriptionAr: 'تحليل بيانات الحجوزات',
      descriptionEn: 'Analyze bookings data',
      path: '/admin/bookings/analytics',
      icon: Icons.analytics_rounded,
      gradientColors: [AppTheme.error, AppTheme.warning],
      searchKeywords: ['تحليل', 'احصائيات', 'analytics', 'statistics'],
      category: ScreenCategory.bookings,
    ),

    // المدفوعات
    SearchableScreen(
      id: 'payments_list',
      titleAr: 'قائمة المدفوعات',
      titleEn: 'Payments List',
      descriptionAr: 'عرض وإدارة المدفوعات',
      descriptionEn: 'View and manage payments',
      path: '/admin/payments',
      icon: Icons.payment_rounded,
      gradientColors: [AppTheme.neonGreen, AppTheme.success],
      searchKeywords: ['مدفوعات', 'دفع', 'payments', 'payment'],
      category: ScreenCategory.financial,
      adminOnly: true,
      visibleForOwner: true,
    ),
    SearchableScreen(
      id: 'payments_analytics',
      titleAr: 'تحليلات المدفوعات',
      titleEn: 'Payments Analytics',
      descriptionAr: 'تحليل بيانات المدفوعات',
      descriptionEn: 'Analyze payments data',
      path: '/admin/payments/analytics',
      icon: Icons.bar_chart_rounded,
      gradientColors: [AppTheme.primaryPurple, AppTheme.primaryBlue],
      searchKeywords: ['تحليل', 'مدفوعات', 'analytics', 'payments'],
      category: ScreenCategory.financial,
      adminOnly: true,
      visibleForOwner: true,
    ),
    SearchableScreen(
      id: 'revenue_dashboard',
      titleAr: 'لوحة الإيرادات',
      titleEn: 'Revenue Dashboard',
      descriptionAr: 'عرض تفاصيل الإيرادات',
      descriptionEn: 'View revenue details',
      path: '/admin/payments/revenue-dashboard',
      icon: Icons.attach_money_rounded,
      gradientColors: [AppTheme.success, AppTheme.primaryCyan],
      searchKeywords: ['ايرادات', 'دخل', 'revenue', 'income'],
      category: ScreenCategory.financial,
      adminOnly: true,
      visibleForOwner: true,
    ),

    // العقارات والوحدات
    SearchableScreen(
      id: 'properties_list',
      titleAr: 'قائمة العقارات',
      titleEn: 'Properties List',
      descriptionAr: 'عرض وإدارة العقارات',
      descriptionEn: 'View and manage properties',
      path: '/admin/properties',
      icon: Icons.apartment_rounded,
      gradientColors: [AppTheme.primaryBlue, AppTheme.primaryViolet],
      searchKeywords: ['عقارات', 'عقار', 'properties', 'property', 'real estate'],
      category: ScreenCategory.properties,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'create_property',
      titleAr: 'إضافة عقار جديد',
      titleEn: 'Add New Property',
      descriptionAr: 'إنشاء عقار جديد في النظام',
      descriptionEn: 'Create a new property in the system',
      path: '/admin/properties/add',
      icon: Icons.add_business_rounded,
      gradientColors: [AppTheme.primaryBlue, AppTheme.success],
      searchKeywords: ['اضافة', 'عقار', 'جديد', 'انشاء', 'add', 'property', 'new', 'create'],
      category: ScreenCategory.properties,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'units_list',
      titleAr: 'قائمة الوحدات',
      titleEn: 'Units List',
      descriptionAr: 'عرض وإدارة الوحدات',
      descriptionEn: 'View and manage units',
      path: '/admin/units',
      icon: Icons.home_rounded,
      gradientColors: [AppTheme.warning, AppTheme.primaryCyan],
      searchKeywords: ['وحدات', 'وحدة', 'units', 'unit', 'apartment'],
      category: ScreenCategory.properties,
      adminOnly: true,
      visibleForOwner: true,
    ),
    SearchableScreen(
      id: 'create_unit',
      titleAr: 'إضافة وحدة جديدة',
      titleEn: 'Add New Unit',
      descriptionAr: 'إنشاء وحدة سكنية جديدة',
      descriptionEn: 'Create a new residential unit',
      path: '/admin/units/add',
      icon: Icons.add_home_work_rounded,
      gradientColors: [AppTheme.warning, AppTheme.success],
      searchKeywords: ['اضافة', 'وحدة', 'جديد', 'انشاء', 'add', 'unit', 'new', 'create'],
      category: ScreenCategory.properties,
      adminOnly: true,
      visibleForOwner: true,
    ),
    SearchableScreen(
      id: 'property_types',
      titleAr: 'أنواع العقارات',
      titleEn: 'Property Types',
      descriptionAr: 'إدارة أنواع العقارات',
      descriptionEn: 'Manage property types',
      path: '/admin/property-types',
      icon: Icons.category_rounded,
      gradientColors: [AppTheme.info, AppTheme.neonBlue],
      searchKeywords: ['انواع', 'عقارات', 'types', 'categories'],
      category: ScreenCategory.properties,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'availability_pricing',
      titleAr: 'التوافر والتسعير',
      titleEn: 'Availability & Pricing',
      descriptionAr: 'إدارة التوافر والأسعار',
      descriptionEn: 'Manage availability and pricing',
      path: '/admin/availability-pricing',
      icon: Icons.price_change_rounded,
      gradientColors: [AppTheme.primaryPurple, AppTheme.warning],
      searchKeywords: ['توافر', 'اسعار', 'تسعير', 'availability', 'pricing', 'prices'],
      category: ScreenCategory.properties,
      adminOnly: true,
    ),

    // المستخدمون
    SearchableScreen(
      id: 'users_list',
      titleAr: 'قائمة المستخدمين',
      titleEn: 'Users List',
      descriptionAr: 'عرض وإدارة المستخدمين',
      descriptionEn: 'View and manage users',
      path: '/admin/users',
      icon: Icons.people_rounded,
      gradientColors: [AppTheme.primaryViolet, AppTheme.neonPurple],
      searchKeywords: ['مستخدمين', 'مستخدم', 'users', 'user', 'clients'],
      category: ScreenCategory.users,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'create_user',
      titleAr: 'إضافة مستخدم جديد',
      titleEn: 'Add New User',
      descriptionAr: 'إنشاء حساب مستخدم جديد',
      descriptionEn: 'Create a new user account',
      path: '/admin/users/add',
      icon: Icons.person_add_alt_1_rounded,
      gradientColors: [AppTheme.primaryViolet, AppTheme.success],
      searchKeywords: ['اضافة', 'مستخدم', 'جديد', 'انشاء', 'add', 'user', 'new', 'create'],
      category: ScreenCategory.users,
      adminOnly: true,
    ),

    // الإشعارات
    SearchableScreen(
      id: 'notifications_list',
      titleAr: 'الإشعارات',
      titleEn: 'Notifications',
      descriptionAr: 'عرض وإدارة الإشعارات',
      descriptionEn: 'View and manage notifications',
      path: '/notifications',
      icon: Icons.notifications_rounded,
      gradientColors: [AppTheme.error, AppTheme.primaryViolet],
      searchKeywords: ['اشعارات', 'تنبيهات', 'notifications', 'alerts'],
      category: ScreenCategory.notifications,
    ),
    SearchableScreen(
      id: 'admin_notifications',
      titleAr: 'إدارة الإشعارات',
      titleEn: 'Admin Notifications',
      descriptionAr: 'إدارة إشعارات النظام',
      descriptionEn: 'Manage system notifications',
      path: '/admin/notifications',
      icon: Icons.admin_panel_settings_rounded,
      gradientColors: [AppTheme.primaryCyan, AppTheme.primaryBlue],
      searchKeywords: ['ادارة', 'اشعارات', 'admin', 'notifications'],
      category: ScreenCategory.notifications,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'create_notification',
      titleAr: 'إرسال إشعار جديد',
      titleEn: 'Send New Notification',
      descriptionAr: 'إنشاء وإرسال إشعار جديد للمستخدمين',
      descriptionEn: 'Create and send a new notification to users',
      path: '/admin/notifications/create',
      icon: Icons.notification_add_rounded,
      gradientColors: [AppTheme.primaryCyan, AppTheme.success],
      searchKeywords: ['اضافة', 'اشعار', 'جديد', 'ارسال', 'انشاء', 'add', 'notification', 'new', 'send', 'create'],
      category: ScreenCategory.notifications,
      adminOnly: true,
    ),

    // الخدمات والسياسات
    SearchableScreen(
      id: 'services_list',
      titleAr: 'قائمة الخدمات',
      titleEn: 'Services List',
      descriptionAr: 'عرض وإدارة الخدمات',
      descriptionEn: 'View and manage services',
      path: '/admin/services',
      icon: Icons.room_service_rounded,
      gradientColors: [AppTheme.neonGreen, AppTheme.primaryCyan],
      searchKeywords: ['خدمات', 'خدمة', 'services', 'service'],
      category: ScreenCategory.services,
    ),
    SearchableScreen(
      id: 'create_service',
      titleAr: 'إضافة خدمة جديدة',
      titleEn: 'Add New Service',
      descriptionAr: 'إنشاء خدمة جديدة في النظام',
      descriptionEn: 'Create a new service in the system',
      path: '/admin/services/add',
      icon: Icons.add_circle_outline_rounded,
      gradientColors: [AppTheme.neonGreen, AppTheme.success],
      searchKeywords: ['اضافة', 'خدمة', 'جديد', 'انشاء', 'add', 'service', 'new', 'create'],
      category: ScreenCategory.services,
    ),
    SearchableScreen(
      id: 'amenities_list',
      titleAr: 'قائمة المرافق',
      titleEn: 'Amenities List',
      descriptionAr: 'عرض وإدارة المرافق',
      descriptionEn: 'View and manage amenities',
      path: '/admin/amenities',
      icon: Icons.pool_rounded,
      gradientColors: [AppTheme.info, AppTheme.primaryBlue],
      searchKeywords: ['مرافق', 'وسائل راحة', 'amenities', 'facilities'],
      category: ScreenCategory.services,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'create_amenity',
      titleAr: 'إضافة مرفق جديد',
      titleEn: 'Add New Amenity',
      descriptionAr: 'إنشاء مرفق جديد في النظام',
      descriptionEn: 'Create a new amenity in the system',
      path: '/admin/amenities/add',
      icon: Icons.add_circle_rounded,
      gradientColors: [AppTheme.info, AppTheme.success],
      searchKeywords: ['اضافة', 'مرفق', 'جديد', 'انشاء', 'add', 'amenity', 'new', 'create'],
      category: ScreenCategory.services,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'policies_list',
      titleAr: 'السياسات',
      titleEn: 'Policies',
      descriptionAr: 'عرض وإدارة السياسات',
      descriptionEn: 'View and manage policies',
      path: '/admin/policies',
      icon: Icons.policy_rounded,
      gradientColors: [AppTheme.warning, AppTheme.primaryViolet],
      searchKeywords: ['سياسات', 'قوانين', 'policies', 'rules'],
      category: ScreenCategory.policies,
    ),
    SearchableScreen(
      id: 'create_policy',
      titleAr: 'إضافة سياسة جديدة',
      titleEn: 'Add New Policy',
      descriptionAr: 'إنشاء سياسة جديدة في النظام',
      descriptionEn: 'Create a new policy in the system',
      path: '/admin/policies/add',
      icon: Icons.add_task_rounded,
      gradientColors: [AppTheme.warning, AppTheme.success],
      searchKeywords: ['اضافة', 'سياسة', 'جديد', 'انشاء', 'add', 'policy', 'new', 'create'],
      category: ScreenCategory.policies,
    ),
    SearchableScreen(
      id: 'reviews_list',
      titleAr: 'التقييمات',
      titleEn: 'Reviews',
      descriptionAr: 'عرض وإدارة التقييمات',
      descriptionEn: 'View and manage reviews',
      path: '/admin/reviews',
      icon: Icons.star_rounded,
      gradientColors: [AppTheme.warning, AppTheme.neonPurple],
      searchKeywords: ['تقييمات', 'تقييم', 'reviews', 'ratings'],
      category: ScreenCategory.other,
    ),

    // إدارة النظام
    SearchableScreen(
      id: 'currencies_management',
      titleAr: 'إدارة العملات',
      titleEn: 'Currencies Management',
      descriptionAr: 'إدارة العملات المدعومة',
      descriptionEn: 'Manage supported currencies',
      path: '/admin/currencies',
      icon: Icons.currency_exchange_rounded,
      gradientColors: [AppTheme.success, AppTheme.primaryBlue],
      searchKeywords: ['عملات', 'عملة', 'currencies', 'currency', 'exchange'],
      category: ScreenCategory.settings,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'cities_management',
      titleAr: 'إدارة المدن',
      titleEn: 'Cities Management',
      descriptionAr: 'إدارة المدن والمناطق',
      descriptionEn: 'Manage cities and areas',
      path: '/admin/cities',
      icon: Icons.location_city_rounded,
      gradientColors: [AppTheme.primaryPurple, AppTheme.primaryCyan],
      searchKeywords: ['مدن', 'مدينة', 'مناطق', 'cities', 'city', 'areas'],
      category: ScreenCategory.settings,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'sections_management',
      titleAr: 'إدارة الأقسام',
      titleEn: 'Sections Management',
      descriptionAr: 'إدارة أقسام النظام',
      descriptionEn: 'Manage system sections',
      path: '/admin/sections',
      icon: Icons.dashboard_customize_rounded,
      gradientColors: [AppTheme.primaryViolet, AppTheme.neonGreen],
      searchKeywords: ['اقسام', 'قسم', 'sections', 'section'],
      category: ScreenCategory.settings,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'create_section',
      titleAr: 'إضافة قسم جديد',
      titleEn: 'Add New Section',
      descriptionAr: 'إنشاء قسم جديد في النظام',
      descriptionEn: 'Create a new section in the system',
      path: '/admin/sections/add',
      icon: Icons.add_box_rounded,
      gradientColors: [AppTheme.primaryViolet, AppTheme.success],
      searchKeywords: ['اضافة', 'قسم', 'جديد', 'انشاء', 'add', 'section', 'new', 'create'],
      category: ScreenCategory.settings,
      adminOnly: true,
    ),
    SearchableScreen(
      id: 'audit_logs',
      titleAr: 'سجلات التدقيق',
      titleEn: 'Audit Logs',
      descriptionAr: 'عرض سجلات النظام',
      descriptionEn: 'View system logs',
      path: '/admin/audit-logs',
      icon: Icons.history_rounded,
      gradientColors: [AppTheme.info, AppTheme.primaryViolet],
      searchKeywords: ['سجلات', 'تدقيق', 'logs', 'audit', 'history'],
      category: ScreenCategory.settings,
    ),

    // الإعدادات الشخصية
    SearchableScreen(
      id: 'profile',
      titleAr: 'الملف الشخصي',
      titleEn: 'Profile',
      descriptionAr: 'عرض وتعديل الملف الشخصي',
      descriptionEn: 'View and edit profile',
      path: '/profile',
      icon: Icons.person_rounded,
      gradientColors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
      searchKeywords: ['ملف', 'شخصي', 'profile', 'personal', 'account'],
      category: ScreenCategory.settings,
    ),
    SearchableScreen(
      id: 'profile_edit',
      titleAr: 'تعديل الملف الشخصي',
      titleEn: 'Edit Profile',
      descriptionAr: 'تعديل بيانات الملف الشخصي',
      descriptionEn: 'Edit profile data',
      path: '/profile/edit',
      icon: Icons.edit_rounded,
      gradientColors: [AppTheme.primaryCyan, AppTheme.primaryViolet],
      searchKeywords: ['تعديل', 'ملف', 'edit', 'profile'],
      category: ScreenCategory.settings,
    ),
    SearchableScreen(
      id: 'change_password',
      titleAr: 'تغيير كلمة المرور',
      titleEn: 'Change Password',
      descriptionAr: 'تغيير كلمة المرور الخاصة بك',
      descriptionEn: 'Change your password',
      path: '/profile/change-password',
      icon: Icons.lock_rounded,
      gradientColors: [AppTheme.error, AppTheme.warning],
      searchKeywords: ['كلمة مرور', 'تغيير', 'password', 'change', 'security'],
      category: ScreenCategory.settings,
    ),
    SearchableScreen(
      id: 'language_settings',
      titleAr: 'إعدادات اللغة',
      titleEn: 'Language Settings',
      descriptionAr: 'تغيير لغة التطبيق',
      descriptionEn: 'Change app language',
      path: '/settings/language',
      icon: Icons.language_rounded,
      gradientColors: [AppTheme.info, AppTheme.primaryBlue],
      searchKeywords: ['لغة', 'عربي', 'انجليزي', 'language', 'arabic', 'english'],
      category: ScreenCategory.settings,
    ),
    SearchableScreen(
      id: 'conversations',
      titleAr: 'المحادثات',
      titleEn: 'Conversations',
      descriptionAr: 'عرض وإدارة المحادثات',
      descriptionEn: 'View and manage conversations',
      path: '/conversations',
      icon: Icons.chat_rounded,
      gradientColors: [AppTheme.primaryPurple, AppTheme.neonPurple],
      searchKeywords: ['محادثات', 'دردشة', 'رسائل', 'conversations', 'chat', 'messages'],
      category: ScreenCategory.other,
    ),
  ];

  // البحث في الشاشات
  List<SearchableScreen> searchScreens(String query) {
    if (query.trim().isEmpty) {
      return _getMostVisitedScreens();
    }

    final lowerQuery = query.toLowerCase();
    final results = <SearchableScreen>[];

    for (final screen in _allScreens) {
      int relevanceScore = 0;

      // البحث في العنوان
      if (screen.titleAr.toLowerCase().contains(lowerQuery)) {
        relevanceScore += 10;
      }
      if (screen.titleEn.toLowerCase().contains(lowerQuery)) {
        relevanceScore += 10;
      }

      // البحث في الوصف
      if (screen.descriptionAr.toLowerCase().contains(lowerQuery)) {
        relevanceScore += 5;
      }
      if (screen.descriptionEn.toLowerCase().contains(lowerQuery)) {
        relevanceScore += 5;
      }

      // البحث في الكلمات المفتاحية
      for (final keyword in screen.searchKeywords) {
        if (keyword.toLowerCase().contains(lowerQuery)) {
          relevanceScore += 8;
        }
      }

      // البحث في الفئة
      if (screen.category.toLowerCase().contains(lowerQuery)) {
        relevanceScore += 3;
      }

      if (relevanceScore > 0) {
        // تحديث بيانات الزيارات
        final visitData = _getVisitData(screen.id);
        results.add(screen.copyWith(
          visitCount: visitData['visitCount'] ?? 0,
          lastVisitedAt: visitData['lastVisitedAt'] != null 
              ? DateTime.parse(visitData['lastVisitedAt']) 
              : null,
          isPinned: _isPinned(screen.id),
        ));
      }
    }

    // ترتيب النتائج حسب الصلة والزيارات
    results.sort((a, b) {
      // الشاشات المثبتة أولاً
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // ثم حسب عدد الزيارات
      return b.visitCount.compareTo(a.visitCount);
    });

    return results.take(_maxSuggestions).toList();
  }

  // حفظ سجل البحث
  Future<void> saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final history = await getSearchHistory();
    history.removeWhere((item) => item == query);
    history.insert(0, query);

    if (history.length > _maxSearchHistory) {
      history.removeLast();
    }

    await _prefs.setStringList(_searchHistoryKey, history);
  }

  // الحصول على سجل البحث
  Future<List<String>> getSearchHistory() async {
    return _prefs.getStringList(_searchHistoryKey) ?? [];
  }

  // حفظ زيارة شاشة
  Future<void> saveScreenVisit(String screenId) async {
    final visitHistory = _getVisitHistory();
    
    visitHistory[screenId] = {
      'visitCount': (visitHistory[screenId]?['visitCount'] ?? 0) + 1,
      'lastVisitedAt': DateTime.now().toIso8601String(),
    };

    await _prefs.setString(_visitHistoryKey, jsonEncode(visitHistory));
  }

  // الحصول على سجل الزيارات
  Map<String, dynamic> _getVisitHistory() {
    final historyJson = _prefs.getString(_visitHistoryKey);
    if (historyJson != null) {
      return jsonDecode(historyJson);
    }
    return {};
  }

  // الحصول على بيانات زيارة شاشة محددة
  Map<String, dynamic> _getVisitData(String screenId) {
    final history = _getVisitHistory();
    return history[screenId] ?? {};
  }

  // الحصول على الشاشات الأكثر زيارة
  List<SearchableScreen> _getMostVisitedScreens() {
    final visitHistory = _getVisitHistory();
    final screens = <SearchableScreen>[];

    for (final screen in _allScreens) {
      final visitData = visitHistory[screen.id];
      if (visitData != null && visitData['visitCount'] > 0) {
        screens.add(screen.copyWith(
          visitCount: visitData['visitCount'],
          lastVisitedAt: DateTime.parse(visitData['lastVisitedAt']),
          isPinned: _isPinned(screen.id),
        ));
      }
    }

    screens.sort((a, b) {
      // الشاشات المثبتة أولاً
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // ثم حسب عدد الزيارات
      return b.visitCount.compareTo(a.visitCount);
    });

    return screens.take(8).toList();
  }

  // تثبيت/إلغاء تثبيت شاشة
  Future<void> togglePinScreen(String screenId) async {
    final pinnedScreens = _getPinnedScreens();
    
    if (pinnedScreens.contains(screenId)) {
      pinnedScreens.remove(screenId);
    } else {
      pinnedScreens.add(screenId);
    }

    await _prefs.setStringList(_pinnedScreensKey, pinnedScreens);
  }

  // الحصول على الشاشات المثبتة
  List<String> _getPinnedScreens() {
    return _prefs.getStringList(_pinnedScreensKey) ?? [];
  }

  // التحقق من تثبيت شاشة
  bool _isPinned(String screenId) {
    return _getPinnedScreens().contains(screenId);
  }

  // مسح سجل البحث
  Future<void> clearSearchHistory() async {
    await _prefs.remove(_searchHistoryKey);
  }

  // مسح سجل الزيارات
  Future<void> clearVisitHistory() async {
    await _prefs.remove(_visitHistoryKey);
  }

  // الحصول على اقتراحات سريعة
  List<SearchableScreen> getQuickSuggestions() {
    // دمج الشاشات المثبتة والأكثر زيارة
    final pinnedIds = _getPinnedScreens();
    final suggestions = <SearchableScreen>[];

    // إضافة الشاشات المثبتة أولاً
    for (final id in pinnedIds) {
      final screen = _allScreens.firstWhere(
        (s) => s.id == id,
        orElse: () => _allScreens.first,
      );
      final visitData = _getVisitData(screen.id);
      suggestions.add(screen.copyWith(
        visitCount: visitData['visitCount'] ?? 0,
        lastVisitedAt: visitData['lastVisitedAt'] != null 
            ? DateTime.parse(visitData['lastVisitedAt']) 
            : null,
        isPinned: true,
      ));
    }

    // إضافة الشاشات الأكثر زيارة
    final mostVisited = _getMostVisitedScreens();
    for (final screen in mostVisited) {
      if (!suggestions.any((s) => s.id == screen.id)) {
        suggestions.add(screen);
      }
    }

    return suggestions.take(6).toList();
  }
}
