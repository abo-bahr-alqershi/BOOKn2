import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yemen_booking_app/core/bloc/theme/theme_bloc.dart';
import 'package:yemen_booking_app/injection_container.dart';

// Core Blocs
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/presentation/bloc/settings_event.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/notifications/presentation/bloc/notification_event.dart';
import '../../features/payment/presentation/bloc/payment_bloc.dart';

// Feature Blocs
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/booking/presentation/bloc/booking_bloc.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/property/presentation/bloc/property_bloc.dart';
import '../../features/review/presentation/bloc/review_bloc.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/splash/presentation/bloc/splash_event.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yemen_booking_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:yemen_booking_app/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:yemen_booking_app/features/reference/presentation/bloc/reference_bloc.dart';
import 'package:yemen_booking_app/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:yemen_booking_app/features/splash/presentation/bloc/splash_event.dart';

/// AppBloc - Centralized Bloc Management for Yemen Booking App
///
/// This class manages all the blocs used throughout the application,
/// providing a centralized way to access and manage state across features.
/// It follows the singleton pattern to ensure consistent state management.
class AppBloc {
  // Core Application Blocs
  static late final AuthBloc authBloc;
  static late final SettingsBloc settingsBloc;
  static late final NotificationBloc notificationBloc;
  static late final PaymentBloc paymentBloc;
  static late final ThemeBloc theme;

  // Feature Blocs
  static late final HomeBloc homeBloc;
  static late final SearchBloc searchBloc;
  static late final BookingBloc bookingBloc;
  static late final ChatBloc chatBloc;
  static late final PropertyBloc propertyBloc;
  static late final ReviewBloc reviewBloc;
  static late final FavoritesBloc favoritesBloc;
  static late final SplashBloc splashBloc;
  static late final OnboardingBloc onboardingBloc;

  /// Initialize all blocs with their dependencies
  /// This method should be called after dependency injection is set up
  static void initialize() {
    // Core Application Blocs
    theme = ThemeBloc(prefs: sl());

    authBloc = AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      resetPasswordUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      getCurrentUserUseCase: sl(),
      updateProfileUseCase: sl(),
      uploadUserImageUseCase: sl(),
      changePasswordUseCase: sl(),
      socialLoginUseCase: sl(),
    );

    settingsBloc = SettingsBloc(
      getSettingsUseCase: sl(),
      updateLanguageUseCase: sl(),
      updateThemeUseCase: sl(),
      updateNotificationSettingsUseCase: sl(),
      localDataSource: sl(),
    );

    notificationBloc = NotificationBloc(
      getNotificationsUseCase: sl(),
      markAsReadUseCase: sl(),
      dismissNotificationUseCase: sl(),
      updateNotificationSettingsUseCase: sl(),
    );

    paymentBloc = PaymentBloc(
      processPaymentUseCase: sl(),
      getPaymentHistoryUseCase: sl(),
    );

    // Feature Blocs
    homeBloc = HomeBloc(
      getSectionsUseCase: sl(),
      getSectionDataUseCase: sl(),
      getPropertyTypesUseCase: sl(),
      getUnitTypesWithFieldsUseCase: sl(),
      getPropertyTypesWithUnitsUseCase: sl(),
      homeRepository: sl(),
      dataSyncService: sl(),
      filterStorageService: sl(),
    );

    searchBloc = SearchBloc(
      searchPropertiesUseCase: sl(),
      getSearchFiltersUseCase: sl(),
      getSearchSuggestionsUseCase: sl(),
      searchRepository: sl(),
      sharedPreferences: sl(),
      dataSyncService: sl(),
      filterStorageService: sl(),
    );

    bookingBloc = BookingBloc(
      createBookingUseCase: sl(),
      getBookingDetailsUseCase: sl(),
      cancelBookingUseCase: sl(),
      getUserBookingsUseCase: sl(),
      getUserBookingsSummaryUseCase: sl(),
      addServicesToBookingUseCase: sl(),
      checkAvailabilityUseCase: sl(),
      processPaymentUseCase: sl(),
    );

    chatBloc = ChatBloc(
      getConversationsUseCase: sl(),
      getMessagesUseCase: sl(),
      sendMessageUseCase: sl(),
      createConversationUseCase: sl(),
      deleteConversationUseCase: sl(),
      archiveConversationUseCase: sl(),
      unarchiveConversationUseCase: sl(),
      deleteMessageUseCase: sl(),
      editMessageUseCase: sl(),
      addReactionUseCase: sl(),
      removeReactionUseCase: sl(),
      markAsReadUseCase: sl(),
      uploadAttachmentUseCase: sl(),
      searchChatsUseCase: sl(),
      getAvailableUsersUseCase: sl(),
      updateUserStatusUseCase: sl(),
      getChatSettingsUseCase: sl(),
      updateChatSettingsUseCase: sl(),
      getCurrentUserUseCase: sl(),
      webSocketService: sl(),
      getAdminUsersUseCase: sl(),
    );

    propertyBloc = PropertyBloc(
      getPropertyDetailsUseCase: sl(),
      getPropertyUnitsUseCase: sl(),
      getPropertyReviewsUseCase: sl(),
      addToFavoritesUseCase: sl(),
      removeFromFavoritesUseCase: sl(),
    );

    reviewBloc = ReviewBloc(
      createReviewUseCase: sl(),
      getPropertyReviewsUseCase: sl(),
      getPropertyReviewsSummaryUseCase: sl(),
      uploadReviewImagesUseCase: sl(),
    );

    favoritesBloc = FavoritesBloc(
      getFavoritesUseCase: sl(),
      addToFavoritesUseCase: sl(),
      removeFromFavoritesUseCase: sl(),
      checkFavoriteStatusUseCase: sl(),
    );

    splashBloc = SplashBloc(
      dataSyncService: sl(),
      getPropertyTypesUseCase: sl(),
      getCitiesUseCase: sl(),
      getCurrenciesUseCase: sl(),
    );

    onboardingBloc = OnboardingBloc(
      localStorage: sl(),
      getCitiesUseCase: sl(),
      getCurrenciesUseCase: sl(),
    );
  }

  /// List of all BlocProviders for the application
  /// This list is used in MultiBlocProvider to provide all blocs to the widget tree
  static final List<BlocProvider> providers = [
    BlocProvider(
      create: (_) => theme,
    ),
    // Core Application Blocs
    BlocProvider<SplashBloc>(
      create: (context) => sl<SplashBloc>()..add(const PreloadAppDataEvent()),
    ),
    BlocProvider<OnboardingBloc>(
      create: (context) =>
          sl<OnboardingBloc>()..add(const CheckFirstRunEvent()),
    ),
    // Reference Bloc
    BlocProvider<ReferenceBloc>(
      create: (context) => sl<ReferenceBloc>(),
    ),
    BlocProvider<AuthBloc>(
      create: (context) => authBloc,
    ),
    BlocProvider<SettingsBloc>(
      create: (context) => settingsBloc..add(LoadSettingsEvent()),
    ),
    BlocProvider<NotificationBloc>(
      create: (context) => notificationBloc,
    ),
    BlocProvider<PaymentBloc>(
      create: (context) => paymentBloc,
    ),

    // Feature Blocs
    BlocProvider<HomeBloc>(
      create: (context) => homeBloc,
    ),
    BlocProvider<SearchBloc>(
      create: (context) => searchBloc,
    ),
    BlocProvider<BookingBloc>(
      create: (context) => bookingBloc,
    ),
    BlocProvider<ChatBloc>(
      create: (context) => chatBloc,
    ),
    BlocProvider<PropertyBloc>(
      create: (context) => propertyBloc,
    ),
    BlocProvider<ReviewBloc>(
      create: (context) => reviewBloc,
    ),
    BlocProvider<FavoritesBloc>(
      create: (context) => favoritesBloc,
    ),
  ];

  /// Dispose all blocs to free up resources
  /// This method should be called when the app is being terminated
  static void dispose() {
    // Core Application Blocs
    authBloc.close();
    settingsBloc.close();
    notificationBloc.close();
    paymentBloc.close();

    // Feature Blocs
    homeBloc.close();
    searchBloc.close();
    bookingBloc.close();
    chatBloc.close();
    propertyBloc.close();
    reviewBloc.close();
    favoritesBloc.close();
  }

  /// Initialize all blocs with their initial events
  /// This method should be called when the app starts
  static void initializeEvents() {
    // Check authentication status on app start
    authBloc.add(const CheckAuthStatusEvent());

    // Load settings
    settingsBloc.add(LoadSettingsEvent());

    // Load notifications if user is authenticated
    authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        notificationBloc.add(const LoadNotificationsEvent());
      }
    });
  }

  /// Get a specific bloc instance
  /// This method provides type-safe access to bloc instances
  static T getBloc<T>() {
    switch (T) {
      case AuthBloc:
        return authBloc as T;
      case SettingsBloc:
        return settingsBloc as T;
      case NotificationBloc:
        return notificationBloc as T;
      case PaymentBloc:
        return paymentBloc as T;
      case HomeBloc:
        return homeBloc as T;
      case SearchBloc:
        return searchBloc as T;
      case BookingBloc:
        return bookingBloc as T;
      case ChatBloc:
        return chatBloc as T;
      case PropertyBloc:
        return propertyBloc as T;
      case ReviewBloc:
        return reviewBloc as T;
      case FavoritesBloc:
        return favoritesBloc as T;
      default:
        throw ArgumentError('Bloc type $T is not registered in AppBloc');
    }
  }

  /// Singleton factory constructor
  static final AppBloc _instance = AppBloc._internal();

  factory AppBloc() {
    return _instance;
  }

  AppBloc._internal();
}

/// Extension to provide easy access to dependency injection
/// This allows us to use sl() function in the AppBloc class
extension ServiceLocatorExtension on AppBloc {
  static T sl<T extends Object>() {
    return GetIt.instance<T>();
  }
}
