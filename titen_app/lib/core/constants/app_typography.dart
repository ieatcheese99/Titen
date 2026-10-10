import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions conforming to TITEN Design System (01_DESIGN_SYSTEM.md §2.4)
/// Inter for UI Narrative & Controls, JetBrains Mono for Technical Values & Identifiers
class TitenTypography {
  // --- TITEN DESIGN SYSTEM TOKENS ---

  /// `type.pageTitle`: Inter 600, 22sp / 30 line
  static TextStyle pageTitle({Color? color}) => GoogleFonts.inter(
        fontSize: 22,
        height: 30 / 22,
        fontWeight: FontWeight.w600,
        color: color ?? TitenColors.textMain,
      );

  /// `type.sectionTitle`: Inter 600, 16sp / 24 line
  static TextStyle sectionTitle({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: color ?? TitenColors.textMain,
      );

  /// `type.body`: Inter 400, 14sp / 22 line
  static TextStyle body({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        height: 22 / 14,
        fontWeight: FontWeight.w400,
        color: color ?? TitenColors.textMain,
      );

  /// `type.control`: Inter 500, 14sp / 20 line
  static TextStyle control({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: color ?? TitenColors.textMain,
      );

  /// `type.bodyComfortable`: Inter 400, 16sp / 24 line
  static TextStyle bodyComfortable({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color ?? TitenColors.textMain,
      );

  /// `type.controlComfortable`: Inter 500, 16sp / 24 line
  static TextStyle controlComfortable({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w500,
        color: color ?? TitenColors.textMain,
      );

  /// `type.metadata`: Inter 400, 13sp / 20 line
  static TextStyle metadata({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        height: 20 / 13,
        fontWeight: FontWeight.w400,
        color: color ?? TitenColors.textMuted,
      );

  /// `type.value`: JetBrains Mono 500, 24sp / 32 line
  static TextStyle value({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w500,
        color: color ?? TitenColors.textMain,
      );

  /// `type.valueCompact`: JetBrains Mono 500, 18sp / 26 line
  static TextStyle valueCompact({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w500,
        color: color ?? TitenColors.textMain,
      );

  /// `type.technical`: JetBrains Mono 400, 13sp / 20 line
  static TextStyle technical({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 20 / 13,
        fontWeight: FontWeight.w400,
        color: color ?? TitenColors.textMuted,
      );

  // --- BACKWARD COMPATIBILITY GETTERS ---

  static TextStyle get headlineLarge => pageTitle();
  static TextStyle get headlineMedium => pageTitle().copyWith(fontSize: 18, height: 26 / 18);
  static TextStyle get titleLarge => sectionTitle();
  static TextStyle get bodyLarge => bodyComfortable();
  static TextStyle get bodyMedium => body();
  static TextStyle get bodySmall => metadata();

  static TextStyle get dataDisplay => value().copyWith(fontWeight: FontWeight.w600);
  static TextStyle get dataValue => valueCompact().copyWith(fontWeight: FontWeight.w600);
  static TextStyle get dataLabel => technical().copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5);
  static TextStyle get dataStatus => technical().copyWith(fontWeight: FontWeight.w600);
}
