import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for TITEN Disaster Early Warning System
/// Project: titen-2f970
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDQ4g_fpRgymHOl7ae2tQ9eewp0Vrkz3ow',
    appId: '1:990164300071:web:277b449ff217852648f902',
    messagingSenderId: '990164300071',
    projectId: 'titen-2f970',
    storageBucket: 'titen-2f970.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQ4g_fpRgymHOl7ae2tQ9eewp0Vrkz3ow',
    appId: '1:990164300071:android:277b449ff217852648f902',
    messagingSenderId: '990164300071',
    projectId: 'titen-2f970',
    storageBucket: 'titen-2f970.firebasestorage.app',
  );
}
