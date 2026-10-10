import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Responsive wrapper conforming to 04_RESPONSIVE_MATRIX.md
/// Max width 1600dp on large monitors, centered, with adaptive theme canvas
class ResponsiveShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveShell({
    super.key,
    required this.child,
    this.maxWidth = 1600,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;

    return Container(
      color: tokens.surfaceCanvas,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}
