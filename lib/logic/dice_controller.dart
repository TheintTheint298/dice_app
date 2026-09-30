import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dice_engine.dart';

enum RollState { idle, rolling, done }

class RollRecord {
  RollRecord(this.dice, this.at) : total = dice.fold(0, (a, b) => a + b);
  final List<int> dice;
  final int total;
  final DateTime at;

  Map<String, dynamic> toJson() => {'d': dice, 't': at.millisecondsSinceEpoch};
  factory RollRecord.fromJson(Map<String, dynamic> j) => RollRecord(
      List<int>.from(j['d']), DateTime.fromMillisecondsSinceEpoch(j['t']));
}

class DiceController extends ChangeNotifier {
  DiceController({
    DiceEngine? engine,
    required SharedPreferences prefs,
    this.rollDuration = const Duration(milliseconds: 800),
  })  : _engine = engine ?? DiceEngine(),
        _prefs = prefs {
    _load();
  }

  static const defaultCount = 2, maxHistory = 20;
  final DiceEngine _engine;
  final SharedPreferences _prefs;
  final Duration rollDuration;

  int count = defaultCount;
  List<int> values = [];
  RollState state = RollState.idle;
  bool muted = false, shakeEnabled = false;
  List<RollRecord> history = [];
  bool _disposed = false;

  int get total => values.fold(0, (a, b) => a + b);
  bool get isRolling => state == RollState.rolling;

  void _load() {
    muted = _prefs.getBool('muted') ?? false;
    shakeEnabled = _prefs.getBool('shake') ?? false;
    count = (_prefs.getInt('count') ?? defaultCount).clamp(1, 6);
    try {
      final raw = _prefs.getString('history');
      if (raw != null) {
        history = (jsonDecode(raw) as List)
            .map((e) => RollRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      history = []; // corrupted data: start clean
    }
  }

  void _saveHistory() => _prefs.setString(
      'history', jsonEncode(history.map((r) => r.toJson()).toList()));

  void setCount(int n) {
    if (isRolling) return;
    count = n.clamp(1, 6);
    values = [];
    state = RollState.idle;
    _prefs.setInt('count', count);
    notifyListeners();
  }

  Future<void> roll() async {
    if (isRolling) return;
    values = _engine.roll(count);
    state = RollState.rolling;
    if (!muted) SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    notifyListeners();
    await Future.delayed(rollDuration);
    if (_disposed) return;
    state = RollState.done;
    history.insert(0, RollRecord(values, DateTime.now()));
    if (history.length > maxHistory) history.removeLast();
    _saveHistory();
    notifyListeners();
  }

  void reset() {
    if (isRolling) return;
    count = defaultCount;
    values = [];
    state = RollState.idle;
    _prefs.setInt('count', count);
    notifyListeners();
  }

  void toggleMute() {
    muted = !muted;
    _prefs.setBool('muted', muted);
    notifyListeners();
  }

  void setShake(bool v) {
    shakeEnabled = v;
    _prefs.setBool('shake', v);
    notifyListeners();
  }

  void clearHistory() {
    history = [];
    _prefs.remove('history');
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
