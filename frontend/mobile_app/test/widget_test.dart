import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PomCare/screens/fertilizer/fertilizer_screen.dart';

void main() {
  testWidgets('fertilizer age field accepts a valid tree age from user input',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FertilizerScreen()));

    final ageField = find.byType(TextField).first;
    await tester.enterText(ageField, '5');
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
  });
}
