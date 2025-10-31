import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:yemen_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:yemen_booking_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:yemen_booking_app/features/auth/presentation/pages/login_page.dart';
import 'package:yemen_booking_app/features/chat/presentation/widgets/conversation_loader.dart';
import 'package:yemen_booking_app/features/review/presentation/pages/reviews_list_page.dart';
import 'package:yemen_booking_app/features/review/presentation/pages/write_review_page.dart';
import 'package:yemen_booking_app/features/search/presentation/pages/search_page.dart';
import 'package:yemen_booking_app/presentation/screens/futuristic_main_screen.dart';
import 'package:yemen_booking_app/presentation/screens/splash_screen.dart';
import 'package:yemen_booking_app/features/onboarding/presentation/pages/select_city_currency_page.dart';
import 'package:yemen_booking_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:yemen_booking_app/features/property/presentation/pages/property_details_page.dart';
import 'package:yemen_booking_app/features/search/domain/entities/search_navigation_params.dart';
import '../services/local_storage_service.dart';
import '../injection_container.dart';
import 'package:yemen_booking_app/features/auth/presentation/pages/register_page.dart';
import 'package:yemen_booking_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:yemen_booking_app/features/property/presentation/pages/property_gallery_page.dart';
import 'package:yemen_booking_app/features/booking/presentation/pages/booking_form_page.dart';
import 'package:yemen_booking_app/features/booking/presentation/pages/booking_summary_page.dart';
import 'package:yemen_booking_app/features/booking/presentation/pages/booking_payment_page.dart';
import 'package:yemen_booking_app/features/booking/presentation/pages/booking_confirmation_page.dart';
import 'package:yemen_booking_app/features/booking/presentation/pages/booking_details_page.dart';
import 'package:yemen_booking_app/features/property/domain/entities/property_detail.dart';
import 'package:yemen_booking_app/features/chat/presentation/pages/chat_page.dart';
import 'package:yemen_booking_app/features/chat/presentation/pages/new_conversation_page.dart';
import 'package:yemen_booking_app/features/chat/presentation/pages/conversations_page.dart';
import 'package:yemen_booking_app/features/chat/domain/entities/conversation.dart';
import 'package:yemen_booking_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:yemen_booking_app/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:yemen_booking_app/features/settings/presentation/pages/settings_page.dart';
import 'package:yemen_booking_app/features/settings/presentation/pages/language_settings_page.dart';
import 'package:yemen_booking_app/services/navigation_service.dart';
import 'package:yemen_booking_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:yemen_booking_app/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:yemen_booking_app/features/notifications/presentation/bloc/notification_bloc.dart' as notif_bloc;
import 'package:yemen_booking_app/core/constants/route_constants.dart';
import 'package:yemen_booking_app/features/home/presentation/pages/all_sections_page.dart';
import 'package:yemen_booking_app/features/home/presentation/pages/section_details_page.dart';
import 'package:yemen_booking_app/features/home/domain/entities/section.dart';

class AppRouter {
  static GoRouter build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    return GoRouter(
      navigatorKey: NavigationService.rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final localStorage = sl<LocalStorageService>();
        final isFirstRun = !localStorage.isOnboardingCompleted();

        final goingToLogin = state.matchedLocation == '/login';
        final goingToRegister = state.matchedLocation == '/register';
        final goingToForgot = state.matchedLocation == '/forgot-password';
        final isSplash = state.matchedLocation == '/';
        final isProtected = _protectedPaths.any((p) => state.matchedLocation.startsWith(p));

        if (isSplash) return null; // اترك السبلاش يقرر

        if (isFirstRun && !(goingToLogin || goingToRegister || goingToForgot)) {
          return '/onboarding/select-city-currency';
        }

        if (authState is AuthUnauthenticated && isProtected && !(goingToLogin || goingToRegister || goingToForgot)) {
          return '/login';
        }

        if (authState is AuthAuthenticated && (goingToLogin || goingToRegister || goingToForgot)) {
          return '/main';
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
        // Notifications list
        GoRoute(
          path: '/notifications',
          builder: (context, state) {
            return BlocProvider<notif_bloc.NotificationBloc>(
              create: (_) => sl<notif_bloc.NotificationBloc>(),
              child: const NotificationsPage(),
            );
          },
        ),
        // Notification settings (align with RouteConstants.notificationSettings)
        GoRoute(
          path: '/notifications/settings',
          builder: (context, state) {
            return BlocProvider<notif_bloc.NotificationBloc>(
              create: (_) => sl<notif_bloc.NotificationBloc>(),
              child: const NotificationSettingsPage(),
            );
          },
        ),
        GoRoute(
          path: '/onboarding/select-city-currency',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider.value(
              value: context.read<OnboardingBloc>(),
              child: const SelectCityCurrencyPage(),
            );
          },
        ),
        GoRoute(
          path: '/main',
          builder: (BuildContext context, GoRouterState state) {
            return const MainScreen();
          },
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(
              body: Center(
                child: LoginPage(),
              ),
            );
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
          path: '/forgot-password',
          builder: (BuildContext context, GoRouterState state) {
            return const ForgotPasswordPage();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(
              body: Center(
                child: Text('الملف الشخصي'),
              ),
            );
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
        GoRoute(
          path: '/settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsPage();
          },
        ),
        GoRoute(
          path: '/settings/language',
          builder: (BuildContext context, GoRouterState state) {
            return const LanguageSettingsPage();
          },
        ),
        // Review Routes
        GoRoute(
          path: '/reviews/:propertyId',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            final propertyName = state.extra as String? ?? '';
            return ReviewsListPage(
              propertyId: propertyId,
              propertyName: propertyName,
            );
          },
        ),
        GoRoute(
          path: '/search',
          builder: (BuildContext context, GoRouterState state) {
            final params = state.extra is Map<String, dynamic>
                ? SearchNavigationParams.fromMap(state.extra as Map<String, dynamic>)
                : null;
            return Scaffold(
              body: Center(
                child: SearchPage(initialParams: params),
              ),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.sections,
          builder: (BuildContext context, GoRouterState state) {
            return const AllSectionsPage();
          },
        ),
        GoRoute(
          path: '/section/:id',
          builder: (BuildContext context, GoRouterState state) {
            final id = state.pathParameters['id']!;
            final section = state.extra is Section ? state.extra as Section : null;
            return SectionDetailsPage(sectionId: id, section: section);
          },
        ),
        GoRoute(
          path: '/review/write',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>;
            return WriteReviewPage(
              bookingId: extras['bookingId'] as String,
              propertyId: extras['propertyId'] as String,
              propertyName: extras['propertyName'] as String,
            );
          },
        ),
        // Property details route
        GoRoute(
          path: '/property/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final extras = (state.extra as Map<String, dynamic>?) ?? {};
            // نمرر unitId ضمن extras عند توفره لاستخدامه لاحقاً
            return PropertyDetailsPage(
              propertyId: id,
              userId: null,
              unitId: extras['unitId'] as String?,
            );
          },
        ),
        // Property gallery
        GoRoute(
          path: '/property/:id/gallery',
          builder: (context, state) {
            final extras = (state.extra as Map<String, dynamic>?) ?? {};
            final images = (extras['images'] as List<PropertyImage>?) ?? const <PropertyImage>[];
            final initialIndex = extras['initialIndex'] as int? ?? 0;
            return PropertyGalleryPage(
              images: images,
              initialIndex: initialIndex,
            );
          },
        ),
        // Property reviews alias
        GoRoute(
          path: '/property/:id/reviews',
          builder: (context, state) {
            final propertyId = state.pathParameters['id']!;
            final propertyName = state.extra as String? ?? '';
            return ReviewsListPage(
              propertyId: propertyId,
              propertyName: propertyName,
            );
          },
        ),
        // Booking flow
        GoRoute(
          path: '/booking/form',
          builder: (context, state) {
            final extras = (state.extra as Map<String, dynamic>?) ?? {};
            return BookingFormPage(
              propertyId: (extras['propertyId'] as String?) ?? '',
              propertyName: (extras['propertyName'] as String?) ?? '',
              unitId: extras['unitId'] as String?,
              pricePerNight: (extras['pricePerNight'] as num?)?.toDouble(),
            );
          },
        ),
        GoRoute(
          path: '/booking/summary',
          builder: (context, state) {
            final bookingData = (state.extra as Map<String, dynamic>?) ?? {};
            return BookingSummaryPage(bookingData: bookingData);
          },
        ),
        GoRoute(
          path: '/booking/payment',
          builder: (context, state) {
            final bookingData = (state.extra as Map<String, dynamic>?) ?? {};
            return BookingPaymentPage(bookingData: bookingData);
          },
        ),
        GoRoute(
          path: '/booking/confirmation',
          builder: (context, state) {
            return BookingConfirmationPage(
              booking: state.extra as dynamic,
            );
          },
        ),
        // إضافة مسار تفاصيل الحجز
        GoRoute(
          path: '/booking/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BookingDetailsPage(bookingId: id);
          },
        ),

        // قائمة المحادثات
        GoRoute(
          path: '/conversations',
          builder: (context, state) {
            return const ConversationsPage();
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


  static const List<String> _protectedPaths = <String>[
    '/profile',
    '/review',
    '/reviews',
    '/booking',
    '/payments',
    '/chat',
  ];
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