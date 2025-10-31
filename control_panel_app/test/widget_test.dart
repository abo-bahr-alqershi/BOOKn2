// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookn_cp_app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'package:bookn_cp_app/core/bloc/app_bloc.dart';
import 'package:bookn_cp_app/core/bloc/theme/theme_bloc.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await di.init();
    // Prevent heavy features from initializing in tests
    AppBloc.theme = ThemeBloc(prefs: di.sl());
    AppBloc.authBloc = di.sl();
    AppBloc.chatBloc = di.sl();
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YemenBookingApp());

    // Verify that app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
