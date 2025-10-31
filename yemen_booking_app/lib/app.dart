import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:yemen_booking_app/core/bloc/theme/theme_bloc.dart';
import 'package:yemen_booking_app/core/bloc/theme/theme_state.dart';
import 'package:yemen_booking_app/features/chat/presentation/providers/typing_indicator_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_manager.dart';
import 'routes/app_router.dart';
import 'injection_container.dart' as di;
import 'core/bloc/app_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'core/theme/app_theme.dart';

class YemenBookingApp extends StatelessWidget {
  const YemenBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TypingIndicatorProvider(),
        ),
        ...AppBloc.providers,
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final locale = _localeFrom(settingsState);
          return BlocBuilder<ThemeBloc, ThemeState>(
            bloc: AppBloc.theme,
            builder: (context, themeState) {
              return MaterialApp.router(
                title: 'Yemen Booking',
                debugShowCheckedModeBanner: false,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: themeState.themeMode,
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LocaleManager.supportedLocales,
                routerConfig: AppRouter.build(context),
                builder: (context, child) {
                  AppTheme.init(context, mode: themeState.themeMode);
                  return child!;
                },
              );
            },
          );
        }
      ),
    );
      
  }
}

ThemeMode _themeModeFrom(SettingsState state) {
  if (state is SettingsLoaded) {
    return state.settings.darkMode ? ThemeMode.dark : ThemeMode.light;
  }
  return ThemeMode.system;
}

Locale _localeFrom(SettingsState state) {
  if (state is SettingsLoaded) {
    final code = state.settings.preferredLanguage;
    return Locale(code);
  }
  return const Locale('ar', 'YE');
}
