import 'dart:math';

/// Pure game logic: no Flutter imports, fully unit-testable.
class DiceEngine {
  DiceEngine([Random? random]) : _random = random ?? Random.secure();
  final Random _random;

  static const minDice = 1, maxDice = 6, sides = 6;

  int rollDie() => _random.nextInt(sides) + 1;

  /// Rolls [count] dice; each die is drawn independently.
  List<int> roll(int count) {
    if (count < minDice || count > maxDice) {
      throw RangeError.range(count, minDice, maxDice, 'count');
    }
    return List.generate(count, (_) => rollDie(), growable: false);
  }
}
