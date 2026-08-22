import 'package:flutter/material.dart';
import 'core/theme/titen_theme.dart';
import 'core/router/app_router.dart';

class TitenApp extends StatelessWidget {
  const TitenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TITEN - Sistem Peringatan Dini Bencana (MAGE 12)',
      debugShowCheckedModeBanner: false,
      theme: titenLightTheme(),
      routerConfig: appRouter,
    );
  }
}
