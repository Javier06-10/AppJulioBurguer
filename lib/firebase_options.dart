// TODO Implement this library.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
  show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    case TargetPlatform.macOS:
    return macos;
    case TargetPlatform.windows:
        return windows;
    case TargetPlatform.linux:
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for linux - '
      'you can reconfigure this by running the FlutterFire CLI again.',
    );
    default:
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_cbdjRvBikOtqHk5kv3fIOC_0xJpE1yE',
    appId: '1:355203518916:web:466595a3c1ede73eb69491',
    messagingSenderId: '355203518916',
    projectId: 'julioburguerpizza',
    authDomain: 'julioburguerpizza.firebaseapp.com',
    storageBucket: 'julioburguerpizza.firebasestorage.app',
    measurementId: 'G-YHYW8D42H2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADiSp_BgzayrqLZTPIy3RbhrXxFODSqLQ',
    appId: '1:355203518916:android:e808f9a574c1b7fbb69491',
    messagingSenderId: '355203518916',
    projectId: 'julioburguerpizza',
    storageBucket: 'julioburguerpizza.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBlnpFTU-LBx1D4WC0Wo77rYNTJo6NIMFQ',
    appId: '1:355203518916:ios:bf9357c086b9025fb69491',
    messagingSenderId: '355203518916',
    projectId: 'julioburguerpizza',
    storageBucket: 'julioburguerpizza.firebasestorage.app',
    iosBundleId: 'com.example.flutterJulioburguer',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBlnpFTU-LBx1D4WC0Wo77rYNTJo6NIMFQ',
    appId: '1:355203518916:ios:bf9357c086b9025fb69491',
    messagingSenderId: '355203518916',
    projectId: 'julioburguerpizza',
    storageBucket: 'julioburguerpizza.firebasestorage.app',
    iosBundleId: 'com.example.flutterJulioburguer',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD_cbdjRvBikOtqHk5kv3fIOC_0xJpE1yE',
    appId: '1:355203518916:web:f4631ede8ac7434db69491',
    messagingSenderId: '355203518916',
    projectId: 'julioburguerpizza',
    authDomain: 'julioburguerpizza.firebaseapp.com',
    storageBucket: 'julioburguerpizza.firebasestorage.app',
    measurementId: 'G-0ZH4L34SR2',
  );

}