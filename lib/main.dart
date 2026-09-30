import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logic/dice_controller.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(DiceApp(controller: DiceController(prefs: prefs)));
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key, required this.controller});
  final DiceController controller;

  static const _accent = Color(0xFFFFB020);

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final cs = ColorScheme.fromSeed(seedColor: _accent, brightness: b).copyWith(
      primary: _accent, onPrimary: const Color(0xFF1A1200),
      surface: dark ? const Color(0xFF0E1A2B) : const Color(0xFFF2F4F8),
      surfaceContainerHigh: dark ? const Color(0xFF17263B) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true, colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(backgroundColor: cs.surface, centerTitle: true),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Dice',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: HomeScreen(controller: controller),
      );
}
