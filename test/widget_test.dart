import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dice_app/main.dart';
import 'package:dice_app/logic/dice_controller.dart';

void main() {
  testWidgets('main rolling flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = DiceController(prefs: prefs, rollDuration: const Duration(milliseconds: 100));
    await tester.pumpWidget(DiceApp(controller: c));

    expect(find.text('Tap Roll to throw the dice'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byKey(const Key('countSelector')), matching: find.text('3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('rollButton')));
    await tester.pump();
    expect(find.text('Rolling…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const Key('total')), findsOneWidget);
    expect(find.text('ROLL AGAIN'), findsOneWidget);
    expect(c.values.length, 3);

    await tester.tap(find.byKey(const Key('resetButton')));
    await tester.pump();
    expect(find.text('Tap Roll to throw the dice'), findsOneWidget);

    await tester.tap(find.byTooltip('Roll history'));
    await tester.pumpAndSettle();
    expect(find.text('Roll history'), findsOneWidget);
  });
}
