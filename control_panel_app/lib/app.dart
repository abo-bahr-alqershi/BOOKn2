import 'package:bookn_cp_app/core/bloc/locale/locale_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:bookn_cp_app/core/bloc/theme/theme_bloc.dart';
import 'package:bookn_cp_app/core/bloc/theme/theme_state.dart';
import 'package:bookn_cp_app/core/localization/app_localizations.dart';
import 'package:bookn_cp_app/core/localization/locale_manager.dart';
import 'package:bookn_cp_app/routes/app_router.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'package:bookn_cp_app/core/bloc/app_bloc.dart';
import 'package:bookn_cp_app/services/navigation_service.dart';
// Removed settings bloc dependency
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/services/message_service.dart';

class YemenBookingApp extends StatelessWidget {
  const YemenBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TypingIndicatorProvider removed; ChatBloc maintains typingUsers state
        ...AppBloc.providers,
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        bloc: AppBloc.theme,
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, Locale>(
            bloc: AppBloc.locale,
            builder: (context, localeState) {
              return MaterialApp.router(
                title: 'Yemen Booking',
                debugShowCheckedModeBanner: false,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: themeState.themeMode,
                locale: localeState,
                scaffoldMessengerKey: MessageService.scaffoldMessengerKey,
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
        },
      ),
    );
  }
}

// Settings feature removed: hardcode defaults
