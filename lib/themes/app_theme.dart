import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color black = Color(0xFF121212);
  static const Color darkGray = Color(0xFF1E1E1E);
  static const Color blueFitness = Color(0xFF2979FF);
  static const Color white = Colors.white;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: blueFitness,
        onPrimary: white,
        secondary: blueFitness,
        surface: darkGray,
        onSurface: white,
      ),
      scaffoldBackgroundColor: black,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkGray,
        foregroundColor: white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: darkGray,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blueFitness,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF262626),
        hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIconColor: blueFitness,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme,
      ).apply(bodyColor: white, displayColor: white),
    );
  }
}
