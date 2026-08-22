import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

ThemeData titenLightTheme() {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: TitenColors.baseBackground,
    colorScheme: const ColorScheme.light(
      primary: TitenColors.primaryAccent,
      onPrimary: Colors.white,
      secondary: TitenColors.tacticalCyan,
      onSecondary: Colors.white,
      surface: TitenColors.surfaceWhite,
      onSurface: TitenColors.textMain,
      outline: TitenColors.outlineBorder,
      surfaceContainerLowest: TitenColors.surfaceWhite,
      surfaceContainerLow: TitenColors.surfaceSubtle,
    ),
    dividerTheme: const DividerThemeData(
      color: TitenColors.outlineBorder,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: TitenColors.surfaceWhite,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TitenColors.outlineBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TitenColors.surfaceWhite,
      foregroundColor: TitenColors.textMain,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TitenColors.surfaceWhite,
      selectedItemColor: TitenColors.primaryAccent,
      unselectedItemColor: TitenColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TitenColors.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TitenColors.textMain,
        side: const BorderSide(color: TitenColors.outlineBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TitenColors.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TitenColors.outlineBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TitenColors.outlineBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TitenColors.tacticalCyan, width: 1.5),
      ),
    ),
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
  );
}
