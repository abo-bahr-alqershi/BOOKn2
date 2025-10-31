import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:bookn_cp_app/core/bloc/theme/theme_bloc.dart';
import 'package:bookn_cp_app/injection_container.dart';
import 'package:bookn_cp_app/core/localization/locale_manager.dart';
import 'package:bookn_cp_app/core/bloc/locale/locale_cubit.dart';

// Core Blocs
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
// Removed notifications, payment

// Feature Blocs
import '../../features/chat/presentation/bloc/chat_bloc.dart';
// Removed home, search, booking, property, review, favorites, splash, onboarding
// Removed additional imports of removed features

/// AppBloc - Centralized Bloc Management for Yemen Booking App
///
/// This class manages all the blocs used throughout the application,
/// providing a centralized way to access and manage state across features.
/// It follows the singleton pattern to ensure consistent state management.
class AppBloc {
  // Core Application Blocs
  static late final AuthBloc authBloc;
  static late final SettingsBloc settingsBloc;
  // Removed notifications, payment
  static late final ThemeBloc theme;
  static late final LocaleCubit locale;

  // Feature Blocs
  static late final ChatBloc chatBloc;
  // Removed other feature blocs

  /// Initialize all blocs with their dependencies
  /// This method should be called after dependency injection is set up
  static void initialize() {
    // Core Application Blocs
    theme = ThemeBloc(prefs: sl());
    locale = LocaleCubit(LocaleManager.defaultLocale);
    settingsBloc = sl();

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
    );

    // Removed initialization for notifications, payment

    // Feature Blocs
    // Removed other feature blocs

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
      markMessagesAsReadUseCase: sl(),
      uploadAttachmentUseCase: sl(),
      searchChatsUseCase: sl(),
      getAvailableUsersUseCase: sl(),
      getAdminUsersUseCase: sl(),
      updateUserStatusUseCase: sl(),
      getChatSettingsUseCase: sl(),
      updateChatSettingsUseCase: sl(),
      sendTypingIndicatorUseCase: sl(),
      getCurrentUserUseCase: sl(),
      webSocketService: sl(),
      mediaPipeline: sl(),
    );

    // Removed other feature blocs
  }

  /// List of all BlocProviders for the application
  /// This list is used in MultiBlocProvider to provide all blocs to the widget tree
  static final List<BlocProvider> providers = [
    BlocProvider(
      create: (_) => theme,
    ),
    BlocProvider<LocaleCubit>(
      create: (context) => locale,
    ),
    BlocProvider<SettingsBloc>(
      create: (context) => settingsBloc,
    ),
    BlocProvider<AuthBloc>(
      create: (context) => authBloc,
    ),
    // Feature Blocs
    BlocProvider<ChatBloc>(
      create: (context) => chatBloc,
    ),
  ];

  /// Dispose all blocs to free up resources
  /// This method should be called when the app is being terminated
  static void dispose() {
    // Core Application Blocs
    authBloc.close();
    settingsBloc.close();

    // Feature Blocs
    chatBloc.close();
    // Removed closures
  }

  /// Initialize all blocs with their initial events
  /// This method should be called when the app starts
  static void initializeEvents() {
    // Check authentication status on app start
    authBloc.add(const CheckAuthStatusEvent());
    // Removed settings and notifications listeners
  }

  /// Get a specific bloc instance
  /// This method provides type-safe access to bloc instances
  static T getBloc<T>() {
    switch (T) {
      case SettingsBloc:
        return settingsBloc as T;

      case AuthBloc:
        return authBloc as T;
      // Removed other feature blocs
      case ChatBloc:
        return chatBloc as T;
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
