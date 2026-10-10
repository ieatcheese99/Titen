import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../firebase_options.dart';
import 'notification_service.dart';

/// Live data waits for Firebase without delaying the app's first frame.
/// Initialization failures remain visible through the data providers.
final firebaseBootstrapProvider = FutureProvider<FirebaseApp>((ref) async {
  final app =
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException(
          'Firebase belum siap setelah 20 detik. Muat ulang untuk mencoba lagi.',
          const Duration(seconds: 20),
        ),
      );

  // Notification permissions and platform setup must not block Live data or UI.
  unawaited(_initializeNotifications());
  return app;
});

Future<void> _initializeNotifications() async {
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } catch (error) {
    debugPrint('[Notifikasi] Inisialisasi tidak selesai: $error');
  }
}
