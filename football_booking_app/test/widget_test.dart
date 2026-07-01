import 'package:flutter_test/flutter_test.dart';
import 'package:football_booking_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
  });
}
