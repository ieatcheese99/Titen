import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Responsive wrapper that ensures the layout looks pristine on mobile emulator, web, and desktop
class ResponsiveShell extends StatelessWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TitenColors.baseBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200, // Maximum width for desktop expansion
          ),
          child: child,
        ),
      ),
    );
  }
}
