import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for ThemeMode: light (default per user preference), system, or dark
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
});
