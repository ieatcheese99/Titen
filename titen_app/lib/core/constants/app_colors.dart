import 'package:flutter/material.dart';

/// Semantic token bundle containing fg, bg, and border colors
class SemanticColorSet {
  final Color fg;
  final Color bg;
  final Color border;

  const SemanticColorSet({
    required this.fg,
    required this.bg,
    required this.border,
  });

  SemanticColorSet lerp(SemanticColorSet? other, double t) {
    if (other == null) return this;
    return SemanticColorSet(
      fg: Color.lerp(fg, other.fg, t) ?? fg,
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      border: Color.lerp(border, other.border, t) ?? border,
    );
  }
}

/// ThemeExtension implementation for TITEN Design System Tokens (01_DESIGN_SYSTEM.md)
@immutable
class TitenTokens extends ThemeExtension<TitenTokens> {
  final Color surfaceCanvas;
  final Color surfacePanel;
  final Color surfaceSubtle;
  final Color surfaceRaised;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMetadata;

  final Color borderSubtle;
  final Color borderControl;
  final Color borderFocus;

  final Color actionPrimaryBg;
  final Color actionPrimaryFg;
  final Color telemetryAccent;

  final SemanticColorSet normal;
  final SemanticColorSet warning;
  final SemanticColorSet critical;
  final SemanticColorSet syncing;
  final SemanticColorSet unknown;

  const TitenTokens({
    required this.surfaceCanvas,
    required this.surfacePanel,
    required this.surfaceSubtle,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMetadata,
    required this.borderSubtle,
    required this.borderControl,
    required this.borderFocus,
    required this.actionPrimaryBg,
    required this.actionPrimaryFg,
    required this.telemetryAccent,
    required this.normal,
    required this.warning,
    required this.critical,
    required this.syncing,
    required this.unknown,
  });

  /// Light palette explicitly selected for the TITEN redesign.
  static const light = TitenTokens(
    surfaceCanvas: Color(0xFFF8FAFC),
    surfacePanel: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF1F5F9),
    surfaceRaised: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF0F172A),
    textMetadata: Color(0xFF64748B),
    borderSubtle: Color(0xFFE2E8F0),
    borderControl: Color(0xFF94A3B8),
    borderFocus: Color(0xFF0284C7),
    actionPrimaryBg: Color(0xFF0284C7),
    actionPrimaryFg: Color(0xFFFFFFFF),
    telemetryAccent: Color(0xFF0891B2),
    normal: SemanticColorSet(
      fg: Color(0xFF065F46),
      bg: Color(0xFFECFDF5),
      border: Color(0xFF047857),
    ),
    warning: SemanticColorSet(
      fg: Color(0xFF78350F),
      bg: Color(0xFFFFFBEB),
      border: Color(0xFF92400E),
    ),
    critical: SemanticColorSet(
      fg: Color(0xFF881337),
      bg: Color(0xFFFFF1F2),
      border: Color(0xFFBE123C),
    ),
    syncing: SemanticColorSet(
      fg: Color(0xFF0C4A6E),
      bg: Color(0xFFF0F9FF),
      border: Color(0xFF0369A1),
    ),
    unknown: SemanticColorSet(
      fg: Color(0xFF64748B),
      bg: Color(0xFFF1F5F9),
      border: Color(0xFF94A3B8),
    ),
  );

  /// Dark theme tokens per TITEN 01_DESIGN_SYSTEM.md §2.1 & §2.2
  static const dark = TitenTokens(
    surfaceCanvas: Color(0xFF09090B),
    surfacePanel: Color(0xFF18181B),
    surfaceSubtle: Color(0xFF27272A),
    surfaceRaised: Color(0xFF18181B),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFE4E4E7),
    textMetadata: Color(0xFFB4B4BE),
    borderSubtle: Color(0xFF3F3F46),
    borderControl: Color(0xFF8B8B94),
    borderFocus: Color(0xFF7DD3FC),
    actionPrimaryBg: Color(0xFFFAFAFA),
    actionPrimaryFg: Color(0xFF18181B),
    telemetryAccent: Color(0xFF7DD3FC),
    normal: SemanticColorSet(
      fg: Color(0xFF6EE7B7),
      bg: Color(0xFF052E23),
      border: Color(0xFF34D399),
    ),
    warning: SemanticColorSet(
      fg: Color(0xFFFCD34D),
      bg: Color(0xFF3A2405),
      border: Color(0xFFFBBF24),
    ),
    critical: SemanticColorSet(
      fg: Color(0xFFFDA4AF),
      bg: Color(0xFF3F0A1E),
      border: Color(0xFFFB7185),
    ),
    syncing: SemanticColorSet(
      fg: Color(0xFF7DD3FC),
      bg: Color(0xFF082F49),
      border: Color(0xFF38BDF8),
    ),
    unknown: SemanticColorSet(
      fg: Color(0xFFD4D4D8),
      bg: Color(0xFF27272A),
      border: Color(0xFFA1A1AA),
    ),
  );

  @override
  TitenTokens copyWith({
    Color? surfaceCanvas,
    Color? surfacePanel,
    Color? surfaceSubtle,
    Color? surfaceRaised,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMetadata,
    Color? borderSubtle,
    Color? borderControl,
    Color? borderFocus,
    Color? actionPrimaryBg,
    Color? actionPrimaryFg,
    Color? telemetryAccent,
    SemanticColorSet? normal,
    SemanticColorSet? warning,
    SemanticColorSet? critical,
    SemanticColorSet? syncing,
    SemanticColorSet? unknown,
  }) {
    return TitenTokens(
      surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
      surfacePanel: surfacePanel ?? this.surfacePanel,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMetadata: textMetadata ?? this.textMetadata,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderControl: borderControl ?? this.borderControl,
      borderFocus: borderFocus ?? this.borderFocus,
      actionPrimaryBg: actionPrimaryBg ?? this.actionPrimaryBg,
      actionPrimaryFg: actionPrimaryFg ?? this.actionPrimaryFg,
      telemetryAccent: telemetryAccent ?? this.telemetryAccent,
      normal: normal ?? this.normal,
      warning: warning ?? this.warning,
      critical: critical ?? this.critical,
      syncing: syncing ?? this.syncing,
      unknown: unknown ?? this.unknown,
    );
  }

  @override
  TitenTokens lerp(ThemeExtension<TitenTokens>? other, double t) {
    if (other is! TitenTokens) return this;
    return TitenTokens(
      surfaceCanvas: Color.lerp(surfaceCanvas, other.surfaceCanvas, t) ?? surfaceCanvas,
      surfacePanel: Color.lerp(surfacePanel, other.surfacePanel, t) ?? surfacePanel,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t) ?? surfaceSubtle,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t) ?? surfaceRaised,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMetadata: Color.lerp(textMetadata, other.textMetadata, t) ?? textMetadata,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderControl: Color.lerp(borderControl, other.borderControl, t) ?? borderControl,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t) ?? borderFocus,
      actionPrimaryBg: Color.lerp(actionPrimaryBg, other.actionPrimaryBg, t) ?? actionPrimaryBg,
      actionPrimaryFg: Color.lerp(actionPrimaryFg, other.actionPrimaryFg, t) ?? actionPrimaryFg,
      telemetryAccent: Color.lerp(telemetryAccent, other.telemetryAccent, t) ?? telemetryAccent,
      normal: normal.lerp(other.normal, t),
      warning: warning.lerp(other.warning, t),
      critical: critical.lerp(other.critical, t),
      syncing: syncing.lerp(other.syncing, t),
      unknown: unknown.lerp(other.unknown, t),
    );
  }
}

/// Backward compatibility static tokens & helper getters
class TitenColors {
  // Foundations
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const baseBackground = Color(0xFFF8FAFC);
  static const outlineBorder = Color(0xFFE2E8F0);
  static const surfaceSubtle = Color(0xFFF1F5F9);

  // Typography
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const textSubtle = Color(0xFF64748B);

  // Accents
  static const primaryAccent = Color(0xFF0284C7);
  static const tacticalCyan = Color(0xFF0891B2);
  static const accentSoft = Color(0xFFF0F9FF);

  // Status Indicators
  static const statusAman = Color(0xFF047857);
  static const statusWaspada = Color(0xFF92400E);
  static const statusSiaga = Color(0xFFB45309);
  static const statusAwasLongsor = Color(0xFFBE123C);
  static const statusAwasKarhutla = Color(0xFFEA580C);
}

/// Extension to quickly access TitenTokens from BuildContext
extension TitenTokensX on BuildContext {
  TitenTokens get titenTokens =>
      Theme.of(this).extension<TitenTokens>() ?? TitenTokens.light;
}

/// Helper function to retrieve appropriate semantic color set based on hazard level
SemanticColorSet getHazardColorSet(BuildContext context, int? statusLevel, [int? hazardType]) {
  final tokens = context.titenTokens;
  if (statusLevel == null) return tokens.unknown;

  switch (statusLevel) {
    case 0:
      return tokens.normal;
    case 1:
    case 2:
      return tokens.warning;
    case 3:
      return tokens.critical;
    default:
      return tokens.unknown;
  }
}

/// Helper for backward compatibility
Color getStatusColor(int? statusLevel, int? hazardType) {
  if (statusLevel == null) return TitenColors.textMuted;
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
