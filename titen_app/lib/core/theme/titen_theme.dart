import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Light Theme conforming to TITEN Design System (01_DESIGN_SYSTEM.md)
ThemeData titenLightTheme() {
  const tokens = TitenTokens.light;

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: tokens.surfaceCanvas,
    extensions: const [tokens],
    colorScheme: ColorScheme.light(
      primary: tokens.actionPrimaryBg,
      onPrimary: tokens.actionPrimaryFg,
      secondary: tokens.syncing.fg,
      onSecondary: tokens.surfacePanel,
      surface: tokens.surfacePanel,
      onSurface: tokens.textPrimary,
      outline: tokens.borderControl,
      outlineVariant: tokens.borderSubtle,
      surfaceContainerLowest: tokens.surfaceCanvas,
      surfaceContainerLow: tokens.surfaceSubtle,
      surfaceContainer: tokens.surfacePanel,
      surfaceContainerHigh: tokens.surfaceRaised,
      error: tokens.critical.fg,
      onError: tokens.surfacePanel,
    ),
    dividerTheme: DividerThemeData(
      color: tokens.borderSubtle,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: tokens.surfacePanel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.borderSubtle, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.surfacePanel,
      foregroundColor: tokens.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: tokens.borderSubtle, width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.surfacePanel,
      elevation: 0,
      indicatorColor: tokens.actionPrimaryBg.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.actionPrimaryBg,
          );
        }
        return GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: tokens.textMetadata,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: tokens.actionPrimaryBg, size: 22);
        }
        return IconThemeData(color: tokens.textMetadata, size: 22);
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.actionPrimaryBg,
        foregroundColor: tokens.actionPrimaryFg,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.actionPrimaryBg,
        side: BorderSide(color: tokens.borderControl, width: 1),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surfaceRaised,
      modalBackgroundColor: tokens.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfacePanel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: tokens.borderControl),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: tokens.borderControl),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: tokens.borderFocus, width: 2),
      ),
      hintStyle: GoogleFonts.inter(color: tokens.textMetadata, fontSize: 14),
    ),
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
  );
}

/// Dark Theme conforming to TITEN Design System (01_DESIGN_SYSTEM.md)
ThemeData titenDarkTheme() {
  const tokens = TitenTokens.dark;

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: tokens.surfaceCanvas,
    extensions: const [tokens],
    colorScheme: ColorScheme.dark(
      primary: tokens.actionPrimaryBg,
      onPrimary: tokens.actionPrimaryFg,
      secondary: tokens.syncing.fg,
      onSecondary: tokens.surfacePanel,
      surface: tokens.surfacePanel,
      onSurface: tokens.textPrimary,
      outline: tokens.borderControl,
      outlineVariant: tokens.borderSubtle,
      surfaceContainerLowest: tokens.surfaceCanvas,
      surfaceContainerLow: tokens.surfaceSubtle,
      surfaceContainer: tokens.surfacePanel,
      surfaceContainerHigh: tokens.surfaceRaised,
      error: tokens.critical.fg,
      onError: tokens.surfacePanel,
    ),
    dividerTheme: DividerThemeData(
      color: tokens.borderSubtle,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: tokens.surfacePanel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.borderSubtle, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.surfacePanel,
      foregroundColor: tokens.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: tokens.borderSubtle, width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.surfacePanel,
      elevation: 0,
      indicatorColor: tokens.surfaceSubtle,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          );
        }
        return GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: tokens.textMetadata,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: tokens.textPrimary, size: 22);
        }
        return IconThemeData(color: tokens.textMetadata, size: 22);
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.actionPrimaryBg,
        foregroundColor: tokens.actionPrimaryFg,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.textPrimary,
        side: BorderSide(color: tokens.borderControl, width: 1),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surfaceRaised,
      modalBackgroundColor: tokens.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfacePanel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: tokens.borderControl),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: tokens.borderControl),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: tokens.borderFocus, width: 2),
      ),
      hintStyle: GoogleFonts.inter(color: tokens.textMetadata, fontSize: 14),
    ),
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
  );
}
