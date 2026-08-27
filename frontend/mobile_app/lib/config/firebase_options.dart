import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Client Firebase options for the Flutter app.
///
/// Prefer the FlutterFire-generated [DefaultFirebaseOptions] so Android, iOS,
/// and other platforms use the keys from `google-services.json` / GoogleService-Info.plist.
///
/// `r26-it-087.firebasestorage.app` is the **Storage bucket** (files/images).
/// Structured records go to **Cloud Firestore**.
class AppFirebaseOptions {
  static const projectId = 'r26-it-087';
  static const storageBucket = 'r26-it-087.firebasestorage.app';

  static FirebaseOptions current() => DefaultFirebaseOptions.currentPlatform;
}
