import 'dart:async';
import 'package:bookn_cp_app/features/admin_cities/domain/entities/city.dart';
import 'package:bookn_cp_app/features/admin_cities/presentation/pages/city_form_page.dart';
import 'package:bookn_cp_app/features/admin_units/domain/entities/unit.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_images/unit_images_bloc.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_images/unit_images_event.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:bookn_cp_app/features/auth/presentation/pages/login_page.dart';
import 'package:bookn_cp_app/features/chat/presentation/widgets/conversation_loader.dart';
import 'package:bookn_cp_app/presentation/screens/futuristic_main_screen.dart';
import 'package:bookn_cp_app/presentation/screens/splash_screen.dart';
// Removed imports for deleted features
// Removed unused imports
import 'package:bookn_cp_app/features/auth/presentation/pages/register_page.dart';
import 'package:bookn_cp_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:bookn_cp_app/features/auth/presentation/pages/verify_email_page.dart';
// Removed imports for deleted features
import 'package:bookn_cp_app/features/chat/presentation/pages/chat_page.dart';
import 'package:bookn_cp_app/features/chat/presentation/pages/new_conversation_page.dart';
import 'package:bookn_cp_app/features/chat/presentation/pages/conversations_page.dart';
import 'package:bookn_cp_app/features/chat/domain/entities/conversation.dart';
import 'package:bookn_cp_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:bookn_cp_app/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:bookn_cp_app/features/auth/presentation/pages/profile_page.dart';
// Removed settings pages imports
// Admin Units pages
import 'package:bookn_cp_app/features/admin_units/presentation/pages/units_list_page.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/pages/create_unit_page.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/pages/edit_unit_page.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/pages/unit_details_page.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/units_list/units_list_bloc.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_form/unit_form_bloc.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/bloc/unit_details/unit_details_bloc.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
// Property Types page and blocs
import 'package:bookn_cp_app/features/property_types/presentation/pages/property_types_page.dart';
import 'package:bookn_cp_app/features/property_types/presentation/bloc/property_types/property_types_bloc.dart';
import 'package:bookn_cp_app/features/property_types/presentation/bloc/property_types/property_types_event.dart';
import 'package:bookn_cp_app/features/property_types/presentation/bloc/unit_types/unit_types_bloc.dart';
import 'package:bookn_cp_app/features/property_types/presentation/bloc/unit_type_fields/unit_type_fields_bloc.dart';
// removed wrong properties pages imports (files do not exist)
import 'package:bookn_cp_app/features/admin_services/presentation/pages/admin_services_page.dart';
import 'package:bookn_cp_app/features/admin_services/presentation/pages/create_service_page.dart';
import 'package:bookn_cp_app/features/admin_services/presentation/pages/edit_service_page.dart';
import 'package:bookn_cp_app/features/admin_amenities/presentation/pages/amenities_management_page.dart';
import 'package:bookn_cp_app/features/admin_amenities/presentation/pages/create_amenity_page.dart';
import 'package:bookn_cp_app/features/admin_amenities/presentation/pages/edit_amenity_page.dart';
import 'package:bookn_cp_app/features/admin_policies/presentation/pages/policies_management_page.dart';
import 'package:bookn_cp_app/features/admin_policies/presentation/pages/create_policy_page.dart';
import 'package:bookn_cp_app/features/admin_policies/presentation/pages/edit_policy_page.dart';
import 'package:bookn_cp_app/features/admin_policies/domain/entities/policy.dart';
import 'package:bookn_cp_app/features/admin_reviews/presentation/pages/reviews_list_page.dart';
import 'package:bookn_cp_app/features/admin_reviews/presentation/pages/review_details_page.dart';
// removed unused import: review entity
import 'package:bookn_cp_app/features/admin_reviews/presentation/bloc/reviews_list/reviews_list_bloc.dart'
    as ar_list_bloc;
import 'package:bookn_cp_app/features/admin_reviews/presentation/bloc/review_details/review_details_bloc.dart'
    as ar_details_bloc;
import 'package:bookn_cp_app/features/admin_services/presentation/bloc/services_bloc.dart';
import 'package:bookn_cp_app/features/admin_amenities/presentation/bloc/amenities_bloc.dart'
    as aa_bloc;
import 'package:bookn_cp_app/features/admin_policies/presentation/bloc/policies_bloc.dart'
    as apo_bloc;
import 'package:bookn_cp_app/features/admin_properties/presentation/bloc/property_types/property_types_bloc.dart'
    as ap_pt_bloc;
// Admin Currencies pages & bloc
import 'package:bookn_cp_app/features/admin_currencies/presentation/pages/currencies_management_page.dart'
    as ac_pages;
import 'package:bookn_cp_app/features/admin_currencies/presentation/bloc/currencies_bloc.dart'
    as ac_bloc;
import 'package:bookn_cp_app/features/admin_currencies/presentation/bloc/currencies_event.dart'
    as ac_events;
// Admin Cities page & bloc
import 'package:bookn_cp_app/features/admin_cities/presentation/pages/admin_cities_page.dart'
    as ci_pages;
import 'package:bookn_cp_app/features/admin_cities/presentation/bloc/cities_bloc.dart'
    as ci_bloc;
import 'package:bookn_cp_app/features/admin_cities/presentation/bloc/cities_event.dart'
    as ci_events;
// Admin Audit Logs page & bloc
import 'package:bookn_cp_app/features/admin_audit_logs/presentation/pages/audit_logs_page.dart'
    as al_pages;
import 'package:bookn_cp_app/features/admin_audit_logs/presentation/bloc/audit_logs_bloc.dart'
    as al_bloc;
// Admin Properties pages & blocs
import 'package:bookn_cp_app/features/admin_properties/presentation/pages/properties_list_page.dart'
    as ap_pages;
import 'package:bookn_cp_app/features/admin_properties/presentation/pages/create_property_page.dart'
    as ap_pages;
import 'package:bookn_cp_app/features/admin_properties/presentation/pages/edit_property_page.dart'
    as ap_pages;
import 'package:bookn_cp_app/features/admin_properties/presentation/pages/property_details_page.dart'
    as ap_pages;
import 'package:bookn_cp_app/features/admin_properties/presentation/bloc/properties/properties_bloc.dart'
    as ap_bloc;
import 'package:bookn_cp_app/features/admin_properties/presentation/bloc/property_types/property_types_bloc.dart'
    as ap_prop_pt_bloc;
// Admin Users pages & blocs
import 'package:bookn_cp_app/features/admin_users/presentation/pages/users_list_page.dart'
    as au_pages;
import 'package:bookn_cp_app/features/admin_users/presentation/pages/create_user_page.dart'
    as au_pages;
import 'package:bookn_cp_app/features/admin_users/presentation/pages/user_details_page.dart'
    as au_pages;
import 'package:bookn_cp_app/features/admin_users/presentation/bloc/users_list/users_list_bloc.dart'
    as au_list_bloc;
import 'package:bookn_cp_app/features/admin_users/presentation/bloc/user_details/user_details_bloc.dart'
    as au_details_bloc;
// Admin Availability & Pricing
import 'package:bookn_cp_app/features/admin_availability_pricing/presentation/pages/availability_pricing_page.dart';
import 'package:bookn_cp_app/features/admin_availability_pricing/presentation/bloc/availability/availability_bloc.dart';
import 'package:bookn_cp_app/features/admin_availability_pricing/presentation/bloc/pricing/pricing_bloc.dart';
import 'package:bookn_cp_app/features/onboarding/presentation/pages/select_city_currency_page.dart';
import 'package:bookn_cp_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:bookn_cp_app/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:bookn_cp_app/features/admin_hub/presentation/pages/admin_hub_page.dart';
import 'package:bookn_cp_app/features/notifications/presentation/bloc/notification_bloc.dart'
    as notif_bloc;
import 'package:bookn_cp_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:bookn_cp_app/features/settings/presentation/pages/language_settings_page.dart';
import 'package:bookn_cp_app/features/settings/presentation/bloc/settings_bloc.dart'
    as st_bloc;
import 'package:bookn_cp_app/features/onboarding/presentation/bloc/onboarding_bloc.dart'
    as onboarding_bloc;
import 'package:bookn_cp_app/features/onboarding/presentation/bloc/onboarding_event.dart'
    as onboarding_event;
import 'package:bookn_cp_app/features/reference/presentation/bloc/reference_bloc.dart'
    as ref_bloc;
// Helpers search pages
import 'package:bookn_cp_app/features/helpers/presentation/pages/user_search_page.dart';
import 'package:bookn_cp_app/features/helpers/presentation/pages/property_search_page.dart';
import 'package:bookn_cp_app/features/helpers/presentation/pages/unit_search_page.dart';
import 'package:bookn_cp_app/features/helpers/presentation/pages/city_search_page.dart';
import 'package:bookn_cp_app/features/helpers/presentation/pages/booking_search_page.dart';
import 'package:bookn_cp_app/features/admin_units/presentation/pages/unit_gallery_page.dart';
import 'route_animations.dart';
import 'route_guards.dart' as guards;
import 'package:bookn_cp_app/services/navigation_service.dart';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import 'package:bookn_cp_app/core/constants/storage_constants.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'dart:convert';
// Admin Bookings pages & blocs
import 'package:bookn_cp_app/features/admin_bookings/presentation/pages/bookings_list_page.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/pages/booking_details_page.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/pages/booking_audit_timeline_page.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/pages/booking_calendar_page.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/pages/booking_timeline_page.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/pages/booking_analytics_page.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/bookings_list/bookings_list_bloc.dart'
    as ab_list_bloc;
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/bookings_list/bookings_list_event.dart'
    as ab_list_event;
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/booking_details/booking_details_bloc.dart'
    as ab_details_bloc;
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/booking_details/booking_details_event.dart'
    as ab_details_event;
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/booking_calendar/booking_calendar_bloc.dart'
    as ab_cal_bloc;
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/booking_calendar/booking_calendar_event.dart'
    as ab_cal_event;
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/booking_analytics/booking_analytics_bloc.dart'
    as ab_an_bloc;
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/booking_analytics/booking_analytics_event.dart'
    as ab_an_event;
// Admin Financial pages & blocs
import 'package:bookn_cp_app/features/admin_financial/presentation/pages/transactions_list_page.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/pages/chart_of_accounts_page.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/pages/financial_dashboard_page.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/bloc/accounts/accounts_bloc.dart'
    as fin_acc_bloc;
import 'package:bookn_cp_app/features/admin_financial/presentation/bloc/transactions/transactions_bloc.dart'
    as fin_trans_bloc;
import 'package:bookn_cp_app/features/admin_financial/presentation/bloc/financial_overview/financial_overview_bloc.dart'
    as fin_overview_bloc;
// Admin Payments pages & blocs
import 'package:bookn_cp_app/features/admin_payments/presentation/pages/payments_list_page.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/pages/payment_details_page.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/pages/payment_analytics_page.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/pages/refunds_management_page.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/pages/revenue_dashboard_page.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payments_list/payments_list_bloc.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_details/payment_details_bloc.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_details/payment_details_event.dart'; // 🎯 إضافة
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_analytics/payment_analytics_bloc.dart'
    as pay_an_bloc;
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_refund/payment_refund_bloc.dart';
// Admin Sections pages & blocs
import 'package:bookn_cp_app/features/admin_sections/presentation/pages/sections_list_page.dart'
    as sec_pages;
import 'package:bookn_cp_app/features/admin_sections/presentation/pages/create_section_page.dart'
    as sec_pages;
import 'package:bookn_cp_app/features/admin_sections/presentation/pages/edit_section_page.dart'
    as sec_pages;
import 'package:bookn_cp_app/features/admin_sections/presentation/pages/section_items_management_page.dart'
    as sec_pages;
import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/sections_list/sections_list_bloc.dart'
    as sec_list_bloc;
import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/section_form/section_form_bloc.dart'
    as sec_form_bloc;
import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/section_form/section_form_event.dart'
    as sec_form_event;
import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/section_items/section_items_bloc.dart'
    as sec_items_bloc;
import 'package:bookn_cp_app/core/enums/section_target.dart' as sec_enums;
import 'package:bookn_cp_app/features/admin_notifications/presentation/bloc/admin_notifications_bloc.dart'
    as an_bloc;
import 'package:bookn_cp_app/features/admin_notifications/presentation/bloc/admin_notifications_event.dart'
    as an_events;
import 'package:bookn_cp_app/features/admin_notifications/presentation/pages/admin_notifications_page.dart';
import 'package:bookn_cp_app/features/admin_notifications/presentation/pages/create_admin_notification_page.dart';
import 'package:bookn_cp_app/features/admin_notifications/presentation/pages/user_notifications_page.dart';
import 'package:bookn_cp_app/features/admin_notifications/presentation/pages/user_selector_page.dart'
    as an_selector;
// Notification Channels pages
import 'package:bookn_cp_app/features/notification_channels/presentation/pages/channels_management_page.dart';
import 'package:bookn_cp_app/features/notification_channels/presentation/pages/channel_users_management_page.dart';
import 'package:bookn_cp_app/features/notification_channels/presentation/pages/create_channel_page.dart';
import 'package:bookn_cp_app/features/notification_channels/presentation/pages/edit_channel_page.dart';
import 'package:bookn_cp_app/features/notification_channels/presentation/bloc/channels_bloc.dart';
import 'package:bookn_cp_app/features/notification_channels/presentation/bloc/channels_event.dart';

class AppRouter {
  static GoRouter build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    return GoRouter(
      navigatorKey: NavigationService.rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        // Proactive route guard: if token expired, force logout and go to /login
        try {
          final token = di
              .sl<LocalStorageService>()
              .getData(StorageConstants.accessToken) as String?;
          if (token != null &&
              token.isNotEmpty &&
              _isJwtExpiredRouter(token, skewSeconds: 10)) {
            context.read<AuthBloc>().add(const LogoutEvent());
            return '/login';
          }
        } catch (_) {}

        final authState = context.read<AuthBloc>().state;
        final goingToLogin = state.matchedLocation == '/login';
        final goingToRegister = state.matchedLocation == '/register';
        final goingToForgot = state.matchedLocation == '/forgot-password';
        final isSplash = state.matchedLocation == '/';
        final path = state.matchedLocation;
        final isProtected = guards.isProtectedPath(path);

        if (isSplash) return null;

        if (authState is AuthUnauthenticated &&
            isProtected &&
            !(goingToLogin || goingToRegister || goingToForgot)) {
          return '/login';
        }

        if (authState is AuthAuthenticated &&
            (goingToLogin || goingToRegister || goingToForgot)) {
          // إذا لم يتم التحقق من البريد الإلكتروني، اجبر على صفحة التحقق
          if (!(authState.user.isEmailVerified)) {
            return '/verify-email';
          }
          return '/main';
        }

        // Optional: Admin guard (just redirect to main if not admin)
        if (guards.isAdminPath(path) && !guards.isAdmin(authState)) {
          return '/main';
        }

        // إذا المستخدم مصادق لكن بريده غير مؤكد، امنع الوصول للمسارات المحمية
        if (authState is AuthAuthenticated && !authState.user.isEmailVerified) {
          final goingToVerify = state.matchedLocation == '/verify-email';
          if (!goingToVerify) return '/verify-email';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const SplashScreen();
          },
        ),
        // Onboarding
        GoRoute(
          path: '/onboarding/select-city-currency',
          pageBuilder: (context, state) => slideUpTransitionPage(
            child: MultiBlocProvider(
              providers: [
                BlocProvider<onboarding_bloc.OnboardingBloc>(
                  create: (_) => di.sl<onboarding_bloc.OnboardingBloc>()
                    ..add(const onboarding_event.CheckFirstRunEvent()),
                ),
                BlocProvider<ref_bloc.ReferenceBloc>(
                  create: (_) => di.sl<ref_bloc.ReferenceBloc>(),
                ),
              ],
              child: const SelectCityCurrencyPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/main',
          pageBuilder: (context, state) =>
              fadeTransitionPage(child: const MainScreen()),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) {
            return const LoginPage();
          },
        ),
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) {
            final params = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : {"isFirst": false};
            return RegisterPage(
              isFirst: params["isFirst"] ?? false,
            );
          },
        ),
        GoRoute(
          path: '/verify-email',
          builder: (BuildContext context, GoRouterState state) {
            return const VerifyEmailPage();
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (BuildContext context, GoRouterState state) {
            return const ForgotPasswordPage();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return const ProfilePage();
          },
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (BuildContext context, GoRouterState state) {
            return const EditProfilePage();
          },
        ),
        GoRoute(
          path: '/profile/change-password',
          builder: (BuildContext context, GoRouterState state) {
            return const ChangePasswordPage();
          },
        ),
        // Settings routes removed
        // Removed review and search routes
        // Removed property routes
        
        // Admin Financial
        GoRoute(
          path: '/admin/financial/dashboard',
          builder: (context, state) {
            return BlocProvider<fin_overview_bloc.FinancialOverviewBloc>(
              create: (_) => di.sl<fin_overview_bloc.FinancialOverviewBloc>(),
              child: const FinancialDashboardPage(),
            );
          },
        ),
        GoRoute(
          path: '/admin/financial/transactions',
          builder: (context, state) {
            final qp = state.uri.queryParameters;
            final extra = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : const {};
            final bookingId = (extra['bookingId'] ?? qp['bookingId']) as String?;
            final userId = (extra['userId'] ?? qp['userId']) as String?;
            return BlocProvider<fin_trans_bloc.TransactionsBloc>(
              create: (_) => di.sl<fin_trans_bloc.TransactionsBloc>(),
              child: TransactionsListPage(
                initialBookingId: bookingId,
                initialUserId: userId,
              ),
            );
          },
        ),
        GoRoute(
          path: '/admin/financial/accounts',
          builder: (context, state) {
            return BlocProvider<fin_acc_bloc.AccountsBloc>(
              create: (_) => di.sl<fin_acc_bloc.AccountsBloc>(),
              child: const ChartOfAccountsPage(),
            );
          },
        ),
        
        // Admin Bookings
        GoRoute(
          path: '/admin/payments',
          builder: (context, state) {
            return BlocProvider<PaymentsListBloc>(
              create: (_) => di.sl<PaymentsListBloc>(),
              child: const PaymentsListPage(),
            );
          },
        ),
        // Settings - Language
        GoRoute(
          path: '/settings/language',
          builder: (context, state) {
            return BlocProvider<st_bloc.SettingsBloc>(
              create: (_) => di.sl<st_bloc.SettingsBloc>(),
              child: const LanguageSettingsPage(),
            );
          },
        ),

        GoRoute(
          path: '/admin/payments/analytics',
          builder: (context, state) {
            return BlocProvider<pay_an_bloc.PaymentAnalyticsBloc>(
              create: (_) => pay_an_bloc.PaymentAnalyticsBloc(
                getPaymentAnalyticsUseCase: di.sl(),
                getRevenueReportUseCase: di.sl(),
                getPaymentTrendsUseCase: di.sl(),
                getRefundStatisticsUseCase: di.sl(),
              ),
              child: const PaymentAnalyticsPage(),
            );
          },
        ),

        GoRoute(
          path: '/admin/payments/revenue-dashboard',
          builder: (context, state) {
            return BlocProvider<pay_an_bloc.PaymentAnalyticsBloc>(
              create: (_) => pay_an_bloc.PaymentAnalyticsBloc(
                getPaymentAnalyticsUseCase: di.sl(),
                getRevenueReportUseCase: di.sl(),
                getPaymentTrendsUseCase: di.sl(),
                getRefundStatisticsUseCase: di.sl(),
              ),
              child: const RevenueDashboardPage(),
            );
          },
        ),

        GoRoute(
          path: '/admin/payments/:paymentId',
          builder: (context, state) {
            final paymentId = state.pathParameters['paymentId']!;
            return BlocProvider<PaymentDetailsBloc>(
              create: (_) => di.sl<PaymentDetailsBloc>()
                ..add(LoadPaymentDetailsEvent(paymentId: paymentId)), // 🎯 إضافة event
              child: PaymentDetailsPage(paymentId: paymentId),
            );
          },
        ),

        GoRoute(
          path: '/admin/payments/:paymentId/refunds',
          builder: (context, state) {
            final paymentId = state.pathParameters['paymentId']!;
            return BlocProvider<PaymentRefundBloc>(
              create: (_) => di.sl<PaymentRefundBloc>(),
              child: RefundsManagementPage(paymentId: paymentId),
            );
          },
        ),

        GoRoute(
          path: '/admin/bookings',
          builder: (context, state) {
            return BlocProvider<ab_list_bloc.BookingsListBloc>(
              create: (_) => di.sl<ab_list_bloc.BookingsListBloc>(),
              child: const BookingsListPage(),
            );
          },
        ),
        GoRoute(
          path: '/admin/bookings/upcoming',
          builder: (context, state) {
            final now = DateTime.now();
            final start = DateTime(now.year, now.month, now.day);
            final end = start.add(const Duration(days: 30));
            return BlocProvider<ab_list_bloc.BookingsListBloc>(
              create: (_) => di.sl<ab_list_bloc.BookingsListBloc>(),
              child: BookingsListPage(
                initialStartDate: start,
                initialEndDate: end,
              ),
            );
          },
        ),
        GoRoute(
          path: '/admin/bookings/calendar',
          builder: (context, state) {
            return BlocProvider<ab_cal_bloc.BookingCalendarBloc>(
              create: (_) => di.sl<ab_cal_bloc.BookingCalendarBloc>()
                ..add(ab_cal_event.LoadCalendarBookingsEvent(
                  month: DateTime.now(),
                  view: ab_cal_event.CalendarView.month,
                )),
              child: const BookingCalendarPage(),
            );
          },
        ),
        GoRoute(
          path: '/admin/bookings/timeline',
          builder: (context, state) {
            return BlocProvider<ab_list_bloc.BookingsListBloc>(
              create: (_) => di.sl<ab_list_bloc.BookingsListBloc>(),
              child: const BookingTimelinePage(),
            );
          },
        ),
        GoRoute(
          path: '/admin/bookings/analytics',
          builder: (context, state) {
            final now = DateTime.now();
            return BlocProvider<ab_an_bloc.BookingAnalyticsBloc>(
              create: (_) => di.sl<ab_an_bloc.BookingAnalyticsBloc>()
                ..add(ab_an_event.LoadBookingAnalyticsEvent(
                  startDate: DateTime(now.year, now.month - 1, now.day),
                  endDate: now,
                )),
              child: const BookingAnalyticsPage(),
            );
          },
        ),
        GoRoute(
          path: '/admin/bookings/:bookingId',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return BlocProvider<ab_details_bloc.BookingDetailsBloc>(
              create: (_) => di.sl<ab_details_bloc.BookingDetailsBloc>()
                ..add(ab_details_event.LoadBookingDetailsEvent(
                    bookingId: bookingId)),
              child: BookingDetailsPage(bookingId: bookingId),
            );
          },
        ),

        // Booking Audit Timeline
        GoRoute(
          path: '/admin/bookings/:bookingId/audit',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return BlocProvider<al_bloc.AuditLogsBloc>(
              create: (_) => di.sl<al_bloc.AuditLogsBloc>(),
              child: BookingAuditTimelinePage(bookingId: bookingId),
            );
          },
        ),

        // قائمة المحادثات
        GoRoute(
          path: '/conversations',
          pageBuilder: (context, state) =>
              fadeTransitionPage(child: const ConversationsPage()),
        ),

        // Admin Hub
        GoRoute(
          path: '/admin',
          pageBuilder: (context, state) => scaleFadeTransitionPage(
            child: BlocProvider<notif_bloc.NotificationBloc>(
              create: (_) => di.sl<notif_bloc.NotificationBloc>(),
              child: const AdminHubPage(),
            ),
          ),
        ),

        // Admin Notifications
        GoRoute(
          path: '/admin/notifications',
          builder: (context, state) {
            return BlocProvider<an_bloc.AdminNotificationsBloc>(
              create: (_) => di.sl<an_bloc.AdminNotificationsBloc>()
                ..add(const an_events.LoadAdminNotificationsStatsEvent())
                ..add(const an_events.LoadSystemNotificationsEvent()),
              child: const AdminNotificationsPage(),
            );
          },
        ),

        // Admin Notifications - create one-off
        GoRoute(
          path: '/admin/notifications/create',
          builder: (context, state) {
            return BlocProvider<an_bloc.AdminNotificationsBloc>(
              create: (_) => di.sl<an_bloc.AdminNotificationsBloc>(),
              child: const CreateAdminNotificationPage(isBroadcast: false),
            );
          },
        ),

        // Admin Notifications - broadcast
        GoRoute(
          path: '/admin/notifications/broadcast',
          builder: (context, state) {
            return BlocProvider<an_bloc.AdminNotificationsBloc>(
              create: (_) => di.sl<an_bloc.AdminNotificationsBloc>(),
              child: const CreateAdminNotificationPage(isBroadcast: true),
            );
          },
        ),

        // Admin Notifications - user notifications
        GoRoute(
          path: '/admin/notifications/user/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return MultiBlocProvider(
              providers: [
                BlocProvider<an_bloc.AdminNotificationsBloc>(
                  create: (_) => di.sl<an_bloc.AdminNotificationsBloc>(),
                ),
                BlocProvider<au_details_bloc.UserDetailsBloc>(
                  create: (_) => di.sl<au_details_bloc.UserDetailsBloc>(),
                ),
              ],
              child: UserNotificationsPage(userId: userId),
            );
          },
        ),

        // Notification Channels - management
        GoRoute(
          path: '/admin/notification-channels',
          builder: (context, state) {
            return BlocProvider<ChannelsBloc>(
              create: (_) => di.sl<ChannelsBloc>()
                ..add(const LoadChannelStatisticsEvent())
                ..add(const LoadChannelsEvent()),
              child: const ChannelsManagementPage(),
            );
          },
        ),
        // Notification Channels - channel users management
        GoRoute(
          path: '/admin/notification-channels/:channelId/users',
          builder: (context, state) {
            final channelId = state.pathParameters['channelId']!;
            return BlocProvider<ChannelsBloc>(
              create: (_) => di.sl<ChannelsBloc>()
                ..add(LoadChannelDetailsEvent(channelId))
                ..add(LoadChannelSubscribersEvent(channelId: channelId)),
              child: ChannelUsersManagementPage(channelId: channelId),
            );
          },
        ),
        // Notification Channels - create channel
        GoRoute(
          path: '/admin/notification-channels/create',
          builder: (context, state) {
            return BlocProvider<ChannelsBloc>(
              create: (_) => di.sl<ChannelsBloc>(),
              child: const CreateChannelPage(),
            );
          },
        ),
        // Notification Channels - edit channel
        GoRoute(
          path: '/admin/notification-channels/:channelId/edit',
          builder: (context, state) {
            final channelId = state.pathParameters['channelId']!;
            return BlocProvider<ChannelsBloc>(
              create: (_) => di.sl<ChannelsBloc>()
                ..add(LoadChannelDetailsEvent(channelId)),
              child: EditChannelPage(channelId: channelId),
            );
          },
        ),

        // Helpers - Admin User Selector (optional direct route)
        GoRoute(
          path: '/helpers/select/users',
          builder: (context, state) {
            final params = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : const {};
            return an_selector.AdminUserSelectorPage(
              allowMultiSelect: params['allowMultiSelect'] ?? false,
              initialSearchTerm: params['initialSearchTerm'],
              initialRole: params['initialRole'],
              onUsersSelected: params['onUsersSelected'],
              onUserSelected: params['onUserSelected'],
            );
          },
        ),

        // Admin Units - list
        GoRoute(
          path: '/admin/units',
          builder: (context, state) {
            return BlocProvider<UnitsListBloc>(
              create: (_) =>
                  di.sl<UnitsListBloc>()..add(const LoadUnitsEvent()),
              child: const UnitsListPage(),
            );
          },
        ),

        // Admin Availability & Pricing
        GoRoute(
          path: '/admin/availability-pricing',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<AvailabilityBloc>(
                    create: (_) => di.sl<AvailabilityBloc>()),
                BlocProvider<PricingBloc>(create: (_) => di.sl<PricingBloc>()),
              ],
              child: const AvailabilityPricingPage(),
            );
          },
        ),

        // Admin Units - create
        GoRoute(
          path: '/admin/units/create',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<UnitFormBloc>(
                  create: (_) =>
                      di.sl<UnitFormBloc>()..add(const InitializeFormEvent()),
                ),
                BlocProvider<UnitImagesBloc>(
                  create: (_) => di.sl<UnitImagesBloc>(),
                ),
              ],
              child: const CreateUnitPage(),
            );
          },
        ),

        // Admin Units - edit
        GoRoute(
          path: '/admin/units/:unitId/edit',
          builder: (context, state) {
            final unitId = state.pathParameters['unitId']!;
            return MultiBlocProvider(
              providers: [
                BlocProvider<UnitFormBloc>(
                  create: (_) =>
                      di.sl<UnitFormBloc>()..add(const InitializeFormEvent()),
                ),
                BlocProvider<UnitDetailsBloc>(
                  create: (_) => di.sl<UnitDetailsBloc>()
                    ..add(LoadUnitDetailsEvent(unitId: unitId)),
                ),
                BlocProvider<UnitImagesBloc>(
                  create: (_) => di.sl<UnitImagesBloc>(),
                ),
              ],
              child: EditUnitPage(unitId: unitId),
            );
          },
        ),

        // Admin Units - details
        GoRoute(
          path: '/admin/units/:unitId',
          builder: (context, state) {
            final unitId = state.pathParameters['unitId']!;
            // return BlocProvider<UnitDetailsBloc>(
            //   create: (_) => di.sl<UnitDetailsBloc>()..add(LoadUnitDetailsEvent(unitId: unitId)),
            //   child: UnitDetailsPage(unitId: unitId),
            // );
            return MultiBlocProvider(
              providers: [
                BlocProvider<UnitDetailsBloc>(
                  create: (_) => di.sl<UnitDetailsBloc>()
                    ..add(LoadUnitDetailsEvent(unitId: unitId)),
                ),
                BlocProvider<UnitImagesBloc>(
                  create: (_) => di.sl<UnitImagesBloc>(),
                ),
              ],
              child: UnitDetailsPage(unitId: unitId),
            );
          },
        ),

        // Admin Units - gallery
        GoRoute(
          path: '/admin/units/:unitId/gallery',
          pageBuilder: (context, state) {
            final unitId = state.pathParameters['unitId']!;
            final unit = state.extra as Unit?;
            return CustomTransitionPage(
              child: BlocProvider<UnitImagesBloc>(
                create: (_) => di.sl<UnitImagesBloc>()
                  ..add(LoadUnitImagesEvent(unitId: unitId)),
                child: UnitGalleryPage(unitId: unitId, unit: unit),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          },
        ),

        // Property Types Management
        GoRoute(
          path: '/admin/property-types',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                    create: (_) => di.sl<PropertyTypesBloc>()
                      ..add(const LoadPropertyTypesEvent())),
                BlocProvider(create: (_) => di.sl<UnitTypesBloc>()),
                BlocProvider(create: (_) => di.sl<UnitTypeFieldsBloc>()),
              ],
              child: const AdminPropertyTypesPage(),
            );
          },
        ),

        // Admin Properties
        GoRoute(
          path: '/admin/properties',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<ap_bloc.PropertiesBloc>(
                  create: (_) => di.sl<ap_bloc.PropertiesBloc>()
                    ..add(const ap_bloc.LoadPropertiesEvent(pageSize: 20)),
                ),
                BlocProvider<ap_prop_pt_bloc.PropertyTypesBloc>(
                  create: (_) => di.sl<ap_prop_pt_bloc.PropertyTypesBloc>()
                    ..add(const ap_prop_pt_bloc.LoadPropertyTypesEvent(
                        pageSize: 1000)),
                ),
              ],
              child: const ap_pages.PropertiesListPage(),
            );
          },
        ),

        // Admin Sections - list
        GoRoute(
          path: '/admin/sections',
          builder: (context, state) {
            return BlocProvider<sec_list_bloc.SectionsListBloc>(
              create: (_) => di.sl<sec_list_bloc.SectionsListBloc>(),
              child: const sec_pages.SectionsListPage(),
            );
          },
        ),

        // Admin Sections - create
        GoRoute(
          path: '/admin/sections/create',
          builder: (context, state) {
            return BlocProvider<sec_form_bloc.SectionFormBloc>(
              create: (_) => di.sl<sec_form_bloc.SectionFormBloc>()
                ..add(const sec_form_event.InitializeSectionFormEvent()),
              child: const sec_pages.CreateSectionPage(),
            );
          },
        ),

        // Admin Sections - edit
        GoRoute(
          path: '/admin/sections/:sectionId/edit',
          builder: (context, state) {
            final sectionId = state.pathParameters['sectionId']!;
            return BlocProvider<sec_form_bloc.SectionFormBloc>(
              create: (_) => di.sl<sec_form_bloc.SectionFormBloc>()
                ..add(sec_form_event.InitializeSectionFormEvent(
                    sectionId: sectionId)),
              child: sec_pages.EditSectionPage(sectionId: sectionId),
            );
          },
        ),

        // Admin Sections - manage items
        GoRoute(
          path: '/admin/sections/:sectionId/items',
          builder: (context, state) {
            final sectionId = state.pathParameters['sectionId']!;
            final target = state.extra as sec_enums.SectionTarget? ??
                sec_enums.SectionTarget.properties;
            return BlocProvider<sec_items_bloc.SectionItemsBloc>(
              create: (_) => di.sl<sec_items_bloc.SectionItemsBloc>(),
              child: sec_pages.SectionItemsManagementPage(
                sectionId: sectionId,
                target: target,
              ),
            );
          },
        ),
        GoRoute(
          path: '/admin/properties/create',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<ap_bloc.PropertiesBloc>(
                    create: (_) => di.sl<ap_bloc.PropertiesBloc>()),
                BlocProvider<ap_prop_pt_bloc.PropertyTypesBloc>(
                    create: (_) => di.sl<ap_prop_pt_bloc.PropertyTypesBloc>()),
              ],
              child: const ap_pages.CreatePropertyPage(),
            );
          },
        ),
        GoRoute(
          path: '/admin/properties/:propertyId',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            return BlocProvider<ap_bloc.PropertiesBloc>(
              create: (_) => di.sl<ap_bloc.PropertiesBloc>(),
              child: ap_pages.PropertyDetailsPage(propertyId: propertyId),
            );
          },
        ),
        GoRoute(
          path: '/admin/properties/:propertyId/edit',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            return MultiBlocProvider(
              providers: [
                BlocProvider<ap_bloc.PropertiesBloc>(
                    create: (_) => di.sl<ap_bloc.PropertiesBloc>()),
                BlocProvider<ap_prop_pt_bloc.PropertyTypesBloc>(
                    create: (_) => di.sl<ap_prop_pt_bloc.PropertyTypesBloc>()),
              ],
              child: ap_pages.EditPropertyPage(propertyId: propertyId),
            );
          },
        ),

        // Admin Services
        GoRoute(
          path: '/admin/services',
          builder: (context, state) {
            return BlocProvider<ServicesBloc>(
              create: (_) => di.sl<ServicesBloc>(),
              child: const AdminServicesPage(),
            );
          },
        ),

        GoRoute(
          path: '/admin/services/create',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final initialPropertyId =
                extra != null ? extra['propertyId'] as String? : null;
            return BlocProvider<ServicesBloc>(
              create: (_) => di.sl<ServicesBloc>(),
              child: CreateServicePage(initialPropertyId: initialPropertyId),
            );
          },
        ),

        GoRoute(
          path: '/admin/services/:serviceId/edit',
          builder: (context, state) {
            final serviceId = state.pathParameters['serviceId']!;
            final service = state.extra; // may pass a Service instance
            return BlocProvider<ServicesBloc>(
              create: (_) => di.sl<ServicesBloc>(),
              child: EditServicePage(
                serviceId: serviceId,
                initialService: service is Object ? service as dynamic : null,
              ),
            );
          },
        ),

        // Admin Amenities (standalone management)
        GoRoute(
          path: '/admin/amenities',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<aa_bloc.AmenitiesBloc>(
                    create: (_) => di.sl<aa_bloc.AmenitiesBloc>()),
                BlocProvider<ap_pt_bloc.PropertyTypesBloc>(
                  create: (_) => di.sl<ap_pt_bloc.PropertyTypesBloc>()
                    ..add(const ap_pt_bloc.LoadPropertyTypesEvent(
                        pageSize: 1000)),
                ),
              ],
              child: const AmenitiesManagementPage(),
            );
          },
        ),

        GoRoute(
          path: '/admin/amenities/create',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<aa_bloc.AmenitiesBloc>(
                    create: (_) => di.sl<aa_bloc.AmenitiesBloc>()),
                BlocProvider<ap_pt_bloc.PropertyTypesBloc>(
                  create: (_) => di.sl<ap_pt_bloc.PropertyTypesBloc>()
                    ..add(const ap_pt_bloc.LoadPropertyTypesEvent(
                        pageSize: 1000)),
                ),
              ],
              child: const CreateAmenityPage(),
            );
          },
        ),

        GoRoute(
          path: '/admin/amenities/:amenityId/edit',
          builder: (context, state) {
            final amenityId = state.pathParameters['amenityId']!;
            final initialAmenity = state.extra;
            return MultiBlocProvider(
              providers: [
                BlocProvider<aa_bloc.AmenitiesBloc>(
                    create: (_) => di.sl<aa_bloc.AmenitiesBloc>()),
                BlocProvider<ap_pt_bloc.PropertyTypesBloc>(
                  create: (_) => di.sl<ap_pt_bloc.PropertyTypesBloc>()
                    ..add(const ap_pt_bloc.LoadPropertyTypesEvent(
                        pageSize: 1000)),
                ),
              ],
              child: EditAmenityPage(
                amenityId: amenityId,
                initialAmenity:
                    initialAmenity is Object ? initialAmenity as dynamic : null,
              ),
            );
          },
        ),

        // Admin Policies (standalone management)
        GoRoute(
          path: '/admin/policies',
          builder: (context, state) {
            return BlocProvider<apo_bloc.PoliciesBloc>(
              create: (_) => di.sl<apo_bloc.PoliciesBloc>(),
              child: const PoliciesManagementPage(),
            );
          },
        ),

        GoRoute(
          path: '/admin/policies/create',
          builder: (context, state) {
            return BlocProvider<apo_bloc.PoliciesBloc>(
              create: (_) => di.sl<apo_bloc.PoliciesBloc>(),
              child: const CreatePolicyPage(),
            );
          },
        ),

        GoRoute(
          path: '/admin/policies/:policyId/edit',
          builder: (context, state) {
            final policyId = state.pathParameters['policyId']!;
            final initialPolicy = state.extra as Policy?;
            return BlocProvider<apo_bloc.PoliciesBloc>(
              create: (_) => di.sl<apo_bloc.PoliciesBloc>(),
              child: EditPolicyPage(
                policyId: policyId,
                initialPolicy: initialPolicy,
              ),
            );
          },
        ),

        // Helpers - Users search
        GoRoute(
          path: '/helpers/search/users',
          builder: (context, state) {
            final params = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : const {};
            return UserSearchPage(
              initialSearchTerm: params['initialSearchTerm'],
              allowMultiSelect: params['allowMultiSelect'] ?? false,
              onUsersSelected: params['onUsersSelected'],
              onUserSelected: params['onUserSelected'],
            );
          },
        ),

        // Helpers - Properties search
        GoRoute(
          path: '/helpers/search/properties',
          builder: (context, state) {
            final params = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : const {};
            return PropertySearchPage(
              initialSearchTerm: params['initialSearchTerm'],
              allowMultiSelect: params['allowMultiSelect'] ?? false,
              onPropertiesSelected: params['onPropertiesSelected'],
              onPropertySelected: params['onPropertySelected'],
            );
          },
        ),

        // Helpers - Units search
        GoRoute(
          path: '/helpers/search/units',
          builder: (context, state) {
            final params = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : const {};
            return UnitSearchPage(
              initialSearchTerm: params['initialSearchTerm'],
              propertyId: params['propertyId'],
              allowMultiSelect: params['allowMultiSelect'] ?? false,
              onUnitsSelected: params['onUnitsSelected'],
              onUnitSelected: params['onUnitSelected'],
            );
          },
        ),

        // Helpers - Cities search
        GoRoute(
          path: '/helpers/search/cities',
          builder: (context, state) {
            final params = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : const {};
            return CitySearchPage(
              initialSearchTerm: params['initialSearchTerm'],
              country: params['country'],
              allowMultiSelect: params['allowMultiSelect'] ?? false,
              onCitiesSelected: params['onCitiesSelected'],
              onCitySelected: params['onCitySelected'],
            );
          },
        ),

        // Helpers - Bookings search
        GoRoute(
          path: '/helpers/search/bookings',
          builder: (context, state) {
            final params = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : const {};
            return BookingSearchPage(
              initialSearchTerm: params['initialSearchTerm'],
              userId: params['userId'],
              unitId: params['unitId'],
              allowMultiSelect: params['allowMultiSelect'] ?? false,
              onBookingsSelected: params['onBookingsSelected'],
              onBookingSelected: params['onBookingSelected'],
            );
          },
        ),

        // Admin Reviews list
        GoRoute(
          path: '/admin/reviews',
          builder: (context, state) {
            return BlocProvider<ar_list_bloc.ReviewsListBloc>(
              create: (_) => di.sl<ar_list_bloc.ReviewsListBloc>(),
              child: const ReviewsListPage(),
            );
          },
        ),

        // Admin Currencies
        GoRoute(
          path: '/admin/currencies',
          builder: (context, state) {
            return BlocProvider<ac_bloc.CurrenciesBloc>(
              create: (_) => di.sl<ac_bloc.CurrenciesBloc>()
                ..add(ac_events.LoadCurrenciesEvent()),
              child: const ac_pages.CurrenciesManagementPage(),
            );
          },
        ),

        // Notifications
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => fadeTransitionPage(
            child: BlocProvider<notif_bloc.NotificationBloc>(
              create: (_) => di.sl<notif_bloc.NotificationBloc>()
                ..add(const LoadNotificationsEvent()),
              child: const NotificationsPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/notifications/settings',
          pageBuilder: (context, state) => slideUpTransitionPage(
            child: MultiBlocProvider(
              providers: [
                BlocProvider<notif_bloc.NotificationBloc>(
                  create: (_) => di.sl<notif_bloc.NotificationBloc>(),
                ),
                BlocProvider<st_bloc.SettingsBloc>(
                  create: (_) => di.sl<st_bloc.SettingsBloc>(),
                ),
              ],
              child: const NotificationSettingsPage(),
            ),
          ),
        ),

        // Admin Cities
        GoRoute(
          path: '/admin/cities',
          builder: (context, state) {
            return BlocProvider<ci_bloc.CitiesBloc>(
              create: (_) => di.sl<ci_bloc.CitiesBloc>()
                ..add(const ci_events.LoadCitiesEvent())
                ..add(ci_events.LoadCitiesStatisticsEvent()),
              child: const ci_pages.AdminCitiesPage(),
            );
          },
        ),

        // Admin Cities - create
        GoRoute(
          path: '/admin/cities/create',
          builder: (context, state) {
            return BlocProvider<ci_bloc.CitiesBloc>(
              create: (_) => di.sl<ci_bloc.CitiesBloc>(),
              child: const CityFormPage(),
            );
          },
        ),

        // Admin Cities - edit
        GoRoute(
          path: '/admin/cities/:cityId/edit',
          builder: (context, state) {
            final city = state.extra as City?;
            return BlocProvider<ci_bloc.CitiesBloc>(
              create: (_) => di.sl<ci_bloc.CitiesBloc>(),
              child: CityFormPage(city: city),
            );
          },
        ),

        // Admin Users - list
        GoRoute(
          path: '/admin/users',
          builder: (context, state) {
            return BlocProvider<au_list_bloc.UsersListBloc>(
              create: (_) => di.sl<au_list_bloc.UsersListBloc>()
                ..add(au_list_bloc.LoadUsersEvent()),
              child: const au_pages.UsersListPage(),
            );
          },
        ),

        // Admin Users - create
        GoRoute(
          path: '/admin/users/create',
          builder: (context, state) {
            // Reuse UsersListBloc for create page for consistency with existing code patterns
            return BlocProvider<au_list_bloc.UsersListBloc>(
              create: (_) => di.sl<au_list_bloc.UsersListBloc>(),
              child: const au_pages.CreateUserPage(),
            );
          },
        ),

        // Admin Users - edit (reuse CreateUserPage with prefilled data)
        GoRoute(
          path: '/admin/users/:userId/edit',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final extras = state.extra as Map<String, dynamic>?;
            return MultiBlocProvider(
              providers: [
                BlocProvider<au_list_bloc.UsersListBloc>(
                  create: (_) => di.sl<au_list_bloc.UsersListBloc>(),
                ),
                BlocProvider<au_details_bloc.UserDetailsBloc>(
                  create: (_) => di.sl<au_details_bloc.UserDetailsBloc>(),
                ),
              ],
              child: au_pages.CreateUserPage(
                userId: userId,
                initialName: extras?['name'] as String?,
                initialEmail: extras?['email'] as String?,
                initialPhone: extras?['phone'] as String?,
                initialRoleId: extras?['roleId'] as String?,
              ),
            );
          },
        ),

        // Admin Users - details
        GoRoute(
          path: '/admin/users/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return BlocProvider<au_details_bloc.UserDetailsBloc>(
              create: (_) => di.sl<au_details_bloc.UserDetailsBloc>()
                ..add(au_details_bloc.LoadUserDetailsEvent(userId: userId)),
              child: au_pages.UserDetailsPage(userId: userId),
            );
          },
        ),

        // Admin Audit Logs
        GoRoute(
          path: '/admin/audit-logs',
          builder: (context, state) {
            return BlocProvider<al_bloc.AuditLogsBloc>(
              create: (_) => di.sl<al_bloc.AuditLogsBloc>(),
              child: const al_pages.AuditLogsPage(),
            );
          },
        ),

        // Admin Review details
        GoRoute(
          path: '/admin/reviews/details',
          builder: (context, state) {
            final reviewId = state.extra as String;
            return BlocProvider<ar_details_bloc.ReviewDetailsBloc>(
              create: (_) => di.sl<ar_details_bloc.ReviewDetailsBloc>(),
              child: ReviewDetailsPage(reviewId: reviewId),
            );
          },
        ),

        // محادثة جديدة
        GoRoute(
          path: '/conversations/new',
          builder: (context, state) {
            return const NewConversationPage();
          },
        ),

        // صفحة المحادثة
        GoRoute(
          path: '/chat/:conversationId',
          builder: (context, state) {
            final conversationId = state.pathParameters['conversationId']!;
            final conversation = state.extra as Conversation?;

            if (conversation != null) {
              return ChatPage(conversation: conversation);
            }

            // إذا لم تمرر المحادثة كـ extra، قم بتحميلها
            return ConversationLoader(conversationId: conversationId);
          },
        ),
      ],
    );
  }

  // Lightweight JWT exp check for router guard
  static bool _isJwtExpiredRouter(String jwt, {int skewSeconds = 0}) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return false;
      final payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      var normalized = payload;
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decoded = String.fromCharCodes(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is int) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(
          expiresAt.subtract(Duration(seconds: skewSeconds)),
        );
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
