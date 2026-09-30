import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dice_app/logic/dice_engine.dart';
import 'package:dice_app/logic/dice_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('results are within 1..6 and count matches', () {
    final e = DiceEngine();
    for (var n = 1; n <= 6; n++) {
      for (var i = 0; i < 500; i++) {
        final r = e.roll(n);
        expect(r.length, n);
        expect(r.every((v) => v >= 1 && v <= 6), isTrue);
      }
    }
  });

  test('all faces occur and distribution is roughly uniform', () {
    final e = DiceEngine();
    final counts = List.filled(7, 0);
    for (var i = 0; i < 12000; i++) {
      counts[e.rollDie()]++;
    }
    for (var f = 1; f <= 6; f++) {
      expect(counts[f], inInclusiveRange(1700, 2300));
    }
  });

  test('invalid counts throw', () {
    expect(() => DiceEngine().roll(0), throwsRangeError);
    expect(() => DiceEngine().roll(7), throwsRangeError);
  });

  test('controller totals, saves and restores history', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = DiceController(
        engine: DiceEngine(Random(1)),
        prefs: prefs,
        rollDuration: Duration.zero);
    c.setCount(4);
    await c.roll();
    expect(c.state, RollState.done);
    expect(c.total, c.values.reduce((a, b) => a + b));
    expect(c.history.length, 1);
    final restored = DiceController(prefs: prefs);
    expect(restored.history.first.dice, c.values);
    c.clearHistory();
    expect(DiceController(prefs: prefs).history, isEmpty);
    c.reset();
    expect(c.count, 2);
    expect(c.state, RollState.idle);
  });
}
