import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color.fromARGB(0, 2, 2, 2),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(0, 45, 45, 45),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF007AFF),
        secondary: Color(0xFF5856D6),
        surface: Color.fromARGB(188, 0, 0, 0),
        // ignore: deprecated_member_use
        background: Color.fromARGB(188, 0, 0, 0),
        onSurface: Colors.white,
        // ignore: deprecated_member_use
        onBackground: Colors.white,
      ),
    );
  }
}