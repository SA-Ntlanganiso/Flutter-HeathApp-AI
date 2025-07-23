import 'package:flutter_test/flutter_test.dart';
import 'package:agcare_plus/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const AGCarePlusApp());

    // Verify our app renders the expected text
    expect(find.text('AGCare+ Mobile App'), findsOneWidget);
  });
}