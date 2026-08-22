import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions: Manrope for UI narrative, JetBrains Mono for Telemetry Data
class TitenTypography {
  // Headings & Structural UI (Manrope)
  static TextStyle get headlineLarge => GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: TitenColors.textMain,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: TitenColors.textMain,
      );

  static TextStyle get titleLarge => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: TitenColors.textMain,
      );

  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: TitenColors.textMain,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: TitenColors.textMain,
      );

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: TitenColors.textMuted,
      );

  // Telemetry & Numeric Data (JetBrains Mono)
  static TextStyle get dataDisplay => GoogleFonts.jetBrainsMono(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: TitenColors.textMain,
        letterSpacing: -0.5,
      );

  static TextStyle get dataValue => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: TitenColors.textMain,
      );

  static TextStyle get dataLabel => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: TitenColors.textMuted,
        letterSpacing: 0.8,
      );

  static TextStyle get dataStatus => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );
}
