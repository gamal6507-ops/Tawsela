import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS || TargetPlatform.macOS => ios,
      TargetPlatform.windows => web,
      _ =>
        throw UnsupportedError(
          'هذه المنصة غير مدعومة حالياً. افتح نسخة الويب.',
        ),
    };
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyB1AoiZbF1XnkYxXOc_ayZfH4QWbrrnHA0',
    appId: '1:816331397345:web:38fa0c1a29122886163fa0',
    messagingSenderId: '816331397345',
    projectId: 'tawsela-gamal6507',
    authDomain: 'tawsela-gamal6507.firebaseapp.com',
  );
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCgolbPE_o3tXKpTGoApKqF6cQkynGFFKo',
    appId: '1:816331397345:android:b4a25bdf86fe3bb9163fa0',
    messagingSenderId: '816331397345',
    projectId: 'tawsela-gamal6507',
  );
  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDZvpE3-WmaGKo9-p9zAykzaDqk8r6fxu4',
    appId: '1:816331397345:ios:f83301fa2be940f9163fa0',
    messagingSenderId: '816331397345',
    projectId: 'tawsela-gamal6507',
    iosBundleId: 'com.toktok.toktok',
  );
}
