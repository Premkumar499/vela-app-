// Basic smoke test – verifies the app boots without throwing.
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_system/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const BillingApp());
    expect(find.byType(BillingApp), findsOneWidget);
  });
}
