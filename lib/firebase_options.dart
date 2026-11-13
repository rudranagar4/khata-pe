// File generated for Firebase project khata-pe (657069485194)
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy_KhataPe_657069485194_WebKey',
    appId: '1:657069485194:web:7f61ad88e0b1f200',
    messagingSenderId: '657069485194',
    projectId: 'khata-pe',
    authDomain: 'khata-pe.firebaseapp.com',
    storageBucket: 'khata-pe.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy_KhataPe_657069485194_AndroidKey',
    appId: '1:657069485194:android:d9571f5b08c908f56e9c40',
    messagingSenderId: '657069485194',
    projectId: 'khata-pe',
    storageBucket: 'khata-pe.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy_KhataPe_657069485194_IosKey',
    appId: '1:657069485194:ios:b2910fa8c35299',
    messagingSenderId: '657069485194',
    projectId: 'khata-pe',
    storageBucket: 'khata-pe.firebasestorage.app',
    iosBundleId: 'com.khatape.khatape',
  );
}

