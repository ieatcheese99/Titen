import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Responsive wrapper that ensures the layout looks pristine on mobile emulator, web, and desktop
class ResponsiveShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveShell({
    super.key,
    required this.child,
    this.maxWidth = 1440,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TitenColors.baseBackground,
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
