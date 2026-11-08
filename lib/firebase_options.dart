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

  // انسخ ديل من google-services.json حقك
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy_انسخ_من_current_key_هنا',
    appId: '1:123456:android:انسخ_mobilesdk_app_id_هنا',
    messagingSenderId: 'انسخ_الرقم_القبل_النقطتين_في_appId',
    projectId: 'tabibak-xxxx_انسخ_project_id_هنا',
    storageBucket: 'tabibak-xxxx.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'نفس_الـ_apiKey',
    appId: 'نفس_الـ_appId',
    messagingSenderId: 'نفس_الـ_messagingSenderId',
    projectId: 'نفس_الـ_projectId',
    storageBucket: 'نفس_الـ_storageBucket',
    iosBundleId: 'com.example.tabibak',
  );
}
