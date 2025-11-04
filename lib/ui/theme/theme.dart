import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. Theme Provider for State Management
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// 2. Main App Theme Configuration
class AppTheme {
  // Using a modern, professional seed color
  static const _seedColor = Colors.indigo;

  // Define a consistent TextTheme using Google Fonts
  static final TextTheme _textTheme = TextTheme(
    // For headlines and titles
    displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 57),
    displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 45),
    displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 36),
    headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 32),
    headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 28),
    headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 24),
    titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 22),
    titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
    titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
    // For body text and labels
    bodyLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.normal),
    labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
    labelMedium: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold),
    labelSmall: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold),
  );

  // Light Theme Configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        elevation: 2,
        shadowColor: Colors.black26,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        elevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}
