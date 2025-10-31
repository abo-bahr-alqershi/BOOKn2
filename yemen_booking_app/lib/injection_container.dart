import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemen_booking_app/core/bloc/theme/theme_bloc.dart';
import 'package:yemen_booking_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:yemen_booking_app/features/search/presentation/bloc/search_bloc.dart';
import 'package:yemen_booking_app/features/splash/presentation/bloc/splash_bloc.dart';

// Core
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';

// Services
import 'services/local_storage_service.dart';
import 'services/filter_storage_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/deep_link_service.dart';
import 'services/websocket_service.dart';
import 'services/local_data_service.dart';
import 'services/connectivity_service.dart';
import 'services/data_sync_service.dart';
// Reference Data
import 'features/reference/data/datasources/reference_remote_datasource.dart';
import 'features/reference/data/datasources/reference_local_datasource.dart';
import 'features/reference/data/repositories/reference_repository_impl.dart';
import 'features/reference/domain/repositories/reference_repository.dart';
import 'features/reference/domain/usecases/get_cities_usecase.dart';
import 'features/reference/domain/usecases/get_currencies_usecase.dart';

// Features - Auth
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/auth/domain/usecases/upload_user_image_usecase.dart';
import 'features/auth/domain/usecases/change_password_usecase.dart';
import 'features/auth/domain/usecases/social_login_usecase.dart';

// Features - Settings
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/get_settings_usecase.dart';
import 'features/settings/domain/usecases/update_language_usecase.dart';
import 'features/settings/domain/usecases/update_theme_usecase.dart';
import 'features/settings/domain/usecases/update_notification_settings_usecase.dart'
    as settings_notification;
import 'features/settings/presentation/bloc/settings_bloc.dart';

// Features - Notifications
import 'features/notifications/data/datasources/notification_local_datasource.dart';
import 'features/notifications/data/datasources/notification_remote_datasource.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'features/notifications/domain/usecases/get_notification_settings_usecase.dart';

import 'features/notifications/domain/usecases/dismiss_notification_usecase.dart';
import 'features/notifications/domain/usecases/update_notification_settings_usecase.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';

// Features - Home
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/domain/usecases/get_sections_usecase.dart';
import 'features/home/domain/usecases/get_section_data_usecase.dart';
import 'features/home/domain/usecases/get_property_types_usecase.dart';
import 'features/home/domain/usecases/get_unit_types_with_fields_usecase.dart';
import 'features/home/domain/usecases/get_property_types_with_units_usecase.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
// Added implementations for Home feature
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/data/datasources/home_remote_datasource.dart';
import 'features/home/data/datasources/home_local_datasource.dart';

// Features - Review
import 'features/review/data/datasources/review_remote_datasource.dart';
import 'features/review/data/repositories/review_repository_impl.dart';
import 'features/review/domain/repositories/review_repository.dart';
import 'features/review/domain/usecases/create_review_usecase.dart';
import 'features/review/domain/usecases/get_property_reviews_usecase.dart';
import 'features/review/domain/usecases/get_property_reviews_Summary_usecase.dart';
import 'features/review/domain/usecases/upload_review_images_usecase.dart';
import 'features/review/presentation/bloc/review_bloc.dart';

// Features - Booking (imports added)
import 'features/booking/presentation/bloc/booking_bloc.dart';
import 'features/booking/domain/usecases/create_booking_usecase.dart';
import 'features/booking/domain/usecases/get_booking_details_usecase.dart';
import 'features/booking/domain/usecases/cancel_booking_usecase.dart';
import 'features/booking/domain/usecases/get_user_bookings_usecase.dart';
import 'features/booking/domain/usecases/get_user_bookings_summary_usecase.dart';
import 'features/booking/domain/usecases/add_services_to_booking_usecase.dart';
import 'features/booking/domain/usecases/check_availability_usecase.dart';
import 'features/booking/domain/repositories/booking_repository.dart';
import 'features/booking/data/repositories/booking_repository_impl.dart';
import 'features/booking/data/datasources/booking_remote_datasource.dart';

// Features - Payment (imports added)
import 'features/payment/data/datasources/payment_remote_datasource.dart';
import 'features/payment/data/repositories/payment_repository_impl.dart';
import 'features/payment/domain/repositories/payment_repository.dart';
import 'features/payment/domain/usecases/process_payment_usecase.dart';
import 'features/payment/domain/usecases/get_payment_history_usecase.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';

// Features - Chat
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/datasources/chat_local_datasource.dart';
import 'features/chat/domain/usecases/get_conversations_usecase.dart';
import 'features/chat/domain/usecases/get_messages_usecase.dart';
import 'features/chat/domain/usecases/send_message_usecase.dart';
import 'features/chat/domain/usecases/create_conversation_usecase.dart';
import 'features/chat/domain/usecases/delete_conversation_usecase.dart';
import 'features/chat/domain/usecases/archive_conversation_usecase.dart';
import 'features/chat/domain/usecases/unarchive_conversation_usecase.dart';
import 'features/chat/domain/usecases/delete_message_usecase.dart';
import 'features/chat/domain/usecases/edit_message_usecase.dart';
import 'features/chat/domain/usecases/add_reaction_usecase.dart';
import 'features/chat/domain/usecases/remove_reaction_usecase.dart';
import 'features/chat/domain/usecases/mark_as_read_usecase.dart';
import 'features/chat/domain/usecases/upload_attachment_usecase.dart';
import 'features/chat/domain/usecases/search_chats_usecase.dart';
import 'features/chat/domain/usecases/get_available_users_usecase.dart';
import 'features/chat/domain/usecases/get_admin_users_usecase.dart';
import 'features/chat/domain/usecases/update_user_status_usecase.dart';
import 'features/chat/domain/usecases/get_chat_settings_usecase.dart';
import 'features/chat/domain/usecases/update_chat_settings_usecase.dart';
// Alias notification MarkAsRead to avoid name conflict
import 'features/notifications/domain/usecases/mark_as_read_usecase.dart'
    as notif;

// Features - Search
import 'features/search/data/datasources/search_remote_datasource.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/domain/repositories/search_repository.dart';
import 'features/search/domain/usecases/search_properties_usecase.dart';
import 'features/search/domain/usecases/get_search_filters_usecase.dart'
    as search_usecases;
import 'features/search/domain/usecases/get_search_suggestions_usecase.dart'
    as search_usecases;

// Features - Property
import 'features/property/presentation/bloc/property_bloc.dart';
import 'features/property/domain/repositories/property_repository.dart';
import 'features/property/domain/usecases/get_property_details_usecase.dart';
import 'features/property/domain/usecases/get_property_units_usecase.dart';
import 'features/property/domain/usecases/get_property_reviews_usecase.dart'
    as property_reviews_usecase;
import 'features/property/domain/usecases/add_to_favorites_usecase.dart';
import 'features/property/domain/usecases/remove_from_favorites_usecase.dart';
import 'features/property/data/datasources/property_remote_datasource.dart';
import 'features/property/data/repositories/property_repository_impl_v2.dart';

// Features - Favorites
import 'features/favorites/domain/repositories/favorites_repository.dart';
import 'features/favorites/data/repositories/favorites_repository_impl.dart';
import 'features/favorites/presentation/bloc/favorites_bloc.dart';
// Favorites feature use cases with prefixes to avoid name clashes with property AddToFavoritesUseCase
import 'features/favorites/domain/usecases/get_favorites_usecase.dart'
    as fav_get;
import 'features/favorites/domain/usecases/add_to_favorites_usecase.dart'
    as fav_add;
import 'features/favorites/domain/usecases/remove_from_favorites_usecase.dart'
    as fav_remove;
import 'features/favorites/domain/usecases/check_favorite_status_usecase.dart'
    as fav_check;

import 'features/reference/presentation/bloc/reference_bloc.dart';
import 'features/reference/presentation/bloc/reference_event.dart';
import 'features/reference/presentation/bloc/reference_state.dart';
import 'features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'features/onboarding/presentation/bloc/onboarding_event.dart';
import 'features/onboarding/presentation/bloc/onboarding_state.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  _initAuth();

  // Features - Settings
  _initSettings();

  // Features - Notifications
  _initNotifications();

  // Features - Home
  _initHome();

  // Features - Review
  _initReview();

  // Features - Search
  _initSearch();

  // Features - Booking
  _initBooking();

  // Features - Payment
  _initPaymentFeature();

  // Features - Chat
  _initChat();

  // Features - Property
  _initPropertyFeature();

  // Features - Favorites
  _initFavoritesFeature();

  // Features - Theme
  _initTheme();

  // Features - Onboarding
  _initOnboarding();

  // Features - Reference Data
  _initReference();

  // Features - Splash
  _initSplash();

  // Core
  _initCore();

  // External
  await _initExternal();
}

void _initAuth() {
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
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
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => UploadUserImageUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => SocialLoginUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      internetConnectionChecker: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );
}

void _initSettings() {
  // Bloc
  sl.registerFactory(
    () => SettingsBloc(
      getSettingsUseCase: sl(),
      updateLanguageUseCase: sl(),
      updateThemeUseCase: sl(),
      updateNotificationSettingsUseCase: sl(),
      localDataSource: AuthLocalDataSourceImpl(sharedPreferences: sl()),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLanguageUseCase(sl()));
  sl.registerLazySingleton(() => UpdateThemeUseCase(sl()));
  sl.registerLazySingleton(
      () => settings_notification.UpdateNotificationSettingsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(localStorage: sl()),
  );
}

void _initNotifications() {
  // Bloc
  sl.registerFactory(
    () => NotificationBloc(
      getNotificationsUseCase: sl(),
      markAsReadUseCase: sl(),
      dismissNotificationUseCase: sl(),
      updateNotificationSettingsUseCase: sl(),
      getUnreadCountUseCase: sl(),
      getNotificationSettingsUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => notif.MarkAsReadUseCase(sl()));
  sl.registerLazySingleton(() => DismissNotificationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNotificationSettingsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationSettingsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(
      apiClient: sl(),
      localStorage: sl(),
      authLocalDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(localStorage: sl()),
  );
}

void _initHome() {
  // Bloc
  sl.registerFactory(
    () => HomeBloc(
      getSectionsUseCase: sl(),
      getSectionDataUseCase: sl(),
      getPropertyTypesUseCase: sl(),
      getUnitTypesWithFieldsUseCase: sl(),
      getPropertyTypesWithUnitsUseCase: sl(),
      homeRepository: sl(),
      dataSyncService: sl(),
      filterStorageService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSectionsUseCase(sl()));
  sl.registerLazySingleton(() => GetSectionDataUseCase(sl()));
  // Stage 2 use cases
  sl.registerLazySingleton(() => GetPropertyTypesUseCase(sl()));
  sl.registerLazySingleton(() => GetUnitTypesWithFieldsUseCase(sl()));
  sl.registerLazySingleton(() => GetPropertyTypesWithUnitsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(apiClient: sl(), localStorage: sl()),
  );
  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(localStorage: sl()),
  );
}

void _initReview() {
  // Bloc
  sl.registerFactory(
    () => ReviewBloc(
      createReviewUseCase: sl(),
      getPropertyReviewsUseCase: sl(),
      getPropertyReviewsSummaryUseCase: sl(),
      uploadReviewImagesUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateReviewUseCase(sl()));
  sl.registerLazySingleton(() => GetPropertyReviewsUseCase(sl()));
  sl.registerLazySingleton(() => GetPropertyReviewsSummaryUseCase(sl()));
  sl.registerLazySingleton(() => UploadReviewImagesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ReviewRemoteDataSource>(
    () => ReviewRemoteDataSourceImpl(apiClient: sl()),
  );
}

void _initSearch() {
  // Bloc
  sl.registerFactory(
    () => SearchBloc(
      searchPropertiesUseCase: sl(),
      getSearchFiltersUseCase: sl(),
      getSearchSuggestionsUseCase: sl(),
      searchRepository: sl(),
      sharedPreferences: sl(),
      dataSyncService: sl(),
      filterStorageService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SearchPropertiesUseCase(sl()));
  sl.registerLazySingleton(() => search_usecases.GetSearchFiltersUseCase(sl()));
  sl.registerLazySingleton(
      () => search_usecases.GetSearchSuggestionsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );

  // Data source
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(apiClient: sl()),
  );
}

void _initBooking() {
  // Bloc
  sl.registerFactory(
    () => BookingBloc(
      createBookingUseCase: sl(),
      getBookingDetailsUseCase: sl(),
      cancelBookingUseCase: sl(),
      getUserBookingsUseCase: sl(),
      getUserBookingsSummaryUseCase: sl(),
      addServicesToBookingUseCase: sl(),
      checkAvailabilityUseCase: sl(),
      processPaymentUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingDetailsUseCase(sl()));
  sl.registerLazySingleton(() => CancelBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetUserBookingsUseCase(sl()));
  sl.registerLazySingleton(() => GetUserBookingsSummaryUseCase(sl()));
  sl.registerLazySingleton(() => AddServicesToBookingUseCase(sl()));
  sl.registerLazySingleton(() => CheckAvailabilityUseCase(sl()));

  // Repository
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      remoteDataSource: sl(),
      internetConnectionChecker: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(apiClient: sl()),
  );
}

void _initPaymentFeature() {
  // Bloc
  sl.registerFactory(
    () => PaymentBloc(
      processPaymentUseCase: sl(),
      getPaymentHistoryUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => ProcessPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentHistoryUseCase(sl()));

  // Repository
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      remoteDataSource: sl(),
      internetConnectionChecker: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(
      apiClient: sl(),
    ),
  );
}

void _initChat() {
  // Bloc
  sl.registerFactory(
    () => ChatBloc(
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
      getAdminUsersUseCase: sl(),
      updateUserStatusUseCase: sl(),
      getChatSettingsUseCase: sl(),
      updateChatSettingsUseCase: sl(),
      getCurrentUserUseCase: sl(),
      webSocketService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => CreateConversationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));
  sl.registerLazySingleton(() => ArchiveConversationUseCase(sl()));
  sl.registerLazySingleton(() => UnarchiveConversationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMessageUseCase(sl()));
  sl.registerLazySingleton(() => EditMessageUseCase(sl()));
  sl.registerLazySingleton(() => AddReactionUseCase(sl()));
  sl.registerLazySingleton(() => RemoveReactionUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  sl.registerLazySingleton(() => UploadAttachmentUseCase(sl()));
  sl.registerLazySingleton(() => SearchChatsUseCase(sl()));
  sl.registerLazySingleton(() => GetAvailableUsersUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminUsersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetChatSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateChatSettingsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      internetConnectionChecker: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(),
  );

  // WebSocket Service
  sl.registerLazySingleton(() => ChatWebSocketService(
        authLocalDataSource: sl(),
      ));
}

void _initPropertyFeature() {
  // Bloc
  sl.registerFactory(
    () => PropertyBloc(
      getPropertyDetailsUseCase: sl(),
      getPropertyUnitsUseCase: sl(),
      getPropertyReviewsUseCase: sl(),
      addToFavoritesUseCase: sl(),
      removeFromFavoritesUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPropertyDetailsUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetPropertyUnitsUseCase(repository: sl()));
  sl.registerLazySingleton(() =>
      property_reviews_usecase.GetPropertyReviewsUseCase(repository: sl()));
  sl.registerLazySingleton(() => AddToFavoritesUseCase(repository: sl()));
  sl.registerLazySingleton(() => RemoveFromFavoritesUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<PropertyRemoteDataSource>(
    () => PropertyRemoteDataSourceImpl(apiClient: sl()),
  );
}

void _initFavoritesFeature() {
  // Bloc
  sl.registerFactory(() => FavoritesBloc(
        getFavoritesUseCase: sl(),
        addToFavoritesUseCase: sl(),
        removeFromFavoritesUseCase: sl(),
        checkFavoriteStatusUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => fav_get.GetFavoritesUseCase(sl()));
  sl.registerLazySingleton(() => fav_add.AddToFavoritesUseCase(sl()));
  sl.registerLazySingleton(() => fav_remove.RemoveFromFavoritesUseCase(sl()));
  sl.registerLazySingleton(() => fav_check.CheckFavoriteStatusUseCase(sl()));

  // Repository
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(
      apiClient: sl(),
      networkInfo: sl(),
      localStorage: sl(),
    ),
  );
}

void _initTheme() {
  // Bloc
  sl.registerFactory(
    () => ThemeBloc(
      prefs: sl(),
    ),
  );
}

void _initOnboarding() {
  // Bloc
  sl.registerFactory(
    () => OnboardingBloc(
      localStorage: sl(),
      getCitiesUseCase: sl(),
      getCurrenciesUseCase: sl(),
    ),
  );
}

void _initReference() {
  // Bloc
  sl.registerFactory(
    () => ReferenceBloc(
      getCitiesUseCase: sl(),
      getCurrenciesUseCase: sl(),
      localStorage: sl(),
    ),
  );
}

void _initSplash() {
  // Bloc
  sl.registerFactory(
    () => SplashBloc(
      dataSyncService: sl(),
      getPropertyTypesUseCase: sl(),
      getCitiesUseCase: sl(),
      getCurrenciesUseCase: sl(),
    ),
  );
}

void _initCore() {
  // Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // API Client
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // Services
  sl.registerLazySingleton(() => LocalStorageService(sl()));
  sl.registerLazySingleton(() => FilterStorageService(sl()));
  sl.registerLazySingleton(() => LocationService());
  sl.registerLazySingleton(() => NotificationService(
        apiClient: sl(),
        localStorage: sl(),
        authLocalDataSource: sl(),
      ));
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => DeepLinkService());

  // Data Management Services
  sl.registerLazySingleton(() => LocalDataService(sl()));
  sl.registerLazySingleton(() => ConnectivityService());

  // Reference datasources and repository
  sl.registerLazySingleton<ReferenceRemoteDataSource>(
      () => ReferenceRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ReferenceLocalDataSource>(
      () => ReferenceLocalDataSourceImpl(localStorage: sl()));
  sl.registerLazySingleton<ReferenceRepository>(
      () => ReferenceRepositoryImpl(remote: sl(), local: sl()));

  // Reference use cases
  sl.registerLazySingleton(() => GetCitiesUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrenciesUseCase(sl()));

  // Data sync service
  sl.registerLazySingleton(() => DataSyncService(
        localDataService: sl(),
        connectivityService: sl(),
        remoteDataSource: sl(),
        referenceRemoteDataSource: sl(),
      ));

  // Removed generic WebSocketService registration; using ChatWebSocketService for chat feature
}

Future<void> _initExternal() async {
  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Dio
  sl.registerLazySingleton(() => Dio());

  // Internet Connection Checker
  sl.registerLazySingleton(() => InternetConnectionChecker());
}
