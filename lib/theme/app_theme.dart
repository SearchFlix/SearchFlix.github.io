import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Vazirmatn', // Universal font for project
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      primaryColor: const Color(0xFFE50914),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE50914),
        secondary: Color(0xFF007AFF),
        surface: Color(0xFF1A1A1A),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
