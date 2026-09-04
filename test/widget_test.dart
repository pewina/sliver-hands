import 'package:flutter_test/flutter_test.dart';
import 'package:sliverhands/app/app.dart';

void main() {
  testWidgets('SilverHands starts with onboarding', (tester) async {
    await tester.pumpWidget(const SilverHandsApp());
    expect(find.text('Welcome to\nSilverHands'), findsOneWidget);
    expect(find.text('Let’s begin'), findsOneWidget);
  });
}
