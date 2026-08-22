import 'package:flutter/material.dart';

/// Firmus Tactical Light Color Tokens
/// Based on TITEN Design System & UI Reference
class TitenColors {
  // Surface & Foundations
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const baseBackground = Color(0xFFF8FAFC);
  static const outlineBorder = Color(0xFFE2E8F0);
  static const surfaceSubtle = Color(0xFFF1F5F9);
  
  // Typography
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const textSubtle = Color(0xFF94A3B8);

  // Tactical Accents
  static const primaryAccent = Color(0xFF059669); // Emerald deep
  static const tacticalCyan = Color(0xFF0284C7);  // High-precision cyan
  static const accentSoft = Color(0xFFE0F2FE);

  // Disaster Status Indicators (FR-1.4 & PRD §9)
  static const statusAman = Color(0xFF10B981);       // Emerald Green (Level 0)
  static const statusWaspada = Color(0xFFF59E0B);    // Amber Yellow (Level 1)
  static const statusSiaga = Color(0xFFF97316);      // Orange (Level 2)
  static const statusAwasLongsor = Color(0xFFEF4444); // Crimson Red (Level 3 - Landslide)
  static const statusAwasKarhutla = Color(0xFFEA580C);// Flame Orange (Level 3 - Forest Fire)
}

/// Helper function to retrieve appropriate status color
Color getStatusColor(int statusLevel, int hazardType) {
  switch (statusLevel) {
    case 0:
      return TitenColors.statusAman;
    case 1:
      return TitenColors.statusWaspada;
    case 2:
      return TitenColors.statusSiaga;
    case 3:
      return hazardType == 2
          ? TitenColors.statusAwasKarhutla
          : TitenColors.statusAwasLongsor;
    default:
      return TitenColors.textMuted;
  }
}
