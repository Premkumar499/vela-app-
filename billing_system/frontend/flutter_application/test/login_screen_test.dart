import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:billing_system/providers/billing_provider.dart';
import 'package:billing_system/screens/login_screen.dart';

Widget _wrap(Widget child) => MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BillingProvider())],
      child: MaterialApp(
        routes: {
          '/dashboard': (_) => const Scaffold(body: Text('Dashboard')),
        },
        home: child,
      ),
    );

void main() {
  group('LoginScreen', () {
    testWidgets('shows password field and login button', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows error on wrong password', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.tap(find.text('Login'));
      await tester.pump();
      expect(find.text('Incorrect password'), findsOneWidget);
    });

    testWidgets('navigates to dashboard on correct password', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('empty password shows error', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.tap(find.text('Login'));
      await tester.pump();
      expect(find.text('Incorrect password'), findsOneWidget);
    });
  });
}
