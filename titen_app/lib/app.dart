import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/titen_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

class TitenApp extends ConsumerWidget {
  const TitenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'TITEN - Sistem Peringatan Dini Bencana (MAGE 12)',
      debugShowCheckedModeBanner: false,
      theme: titenLightTheme(),
      darkTheme: titenDarkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
