import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('ما مدعوم');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_9bYseIXkNAxuM3TQP9RXGUqCh37XPrk',
    appId: '1:50266299347:android:193369d07a4006b9b32d26',
    messagingSenderId: '50266299347',
    projectId: 'tabibek-2f25e',
    storageBucket: 'tabibek-2f25e.firebasestorage.app',
  );

  // Replace these values with the iOS app values only if you build for iOS.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_IOS_SENDER_ID',
    projectId: 'tabibek-2f25e',
    storageBucket: 'tabibek-2f25e.firebasestorage.app',
    iosBundleId: 'com.example.tabibak',
  );
}
