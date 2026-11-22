import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/main.dart';

void main() {
  testWidgets('Little Bumpy app smoke and parity test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LittleBumpyApp());

    // Verify initial render on Today tab
    expect(find.text("Today's 3 Check-Ins"), findsOneWidget);
    expect(find.text('Week 24'), findsOneWidget);
    expect(find.text('Iron (Need of the Day)'), findsOneWidget);

    // Verify medical disclaimer is present
    expect(
      find.text(
        'This app is not medical advice. If you are worried about anything, call your doctor.',
      ),
      findsOneWidget,
    );

    // Tap Check-in
    await tester.tap(find.text('Iron (Need of the Day)'));
    await tester.pumpAndSettle();

    // Verify baby line changes to thank-you
    expect(find.text('Cape on. Thank you!'), findsOneWidget);
  });
}
