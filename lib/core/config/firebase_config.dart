import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public Firebase app identifiers supplied at compile time.
///
/// These values identify a Firebase app; they are not server credentials.
/// Keep service-account JSON and other privileged credentials out of Flutter.
/// See SPEC.md §27, §36.
class FirebaseConfig {
  const FirebaseConfig._();

  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static const androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');

  static bool get isConfigured {
    if (projectId.isEmpty || messagingSenderId.isEmpty) return false;
    final values = _platformValues;
    return values.apiKey.isNotEmpty && values.appId.isNotEmpty;
  }

  static FirebaseOptions get currentPlatformOptions {
    if (!isConfigured) {
      throw StateError('Firebase is not configured for this platform.');
    }
    final values = _platformValues;
    return FirebaseOptions(
      apiKey: values.apiKey,
      appId: values.appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
    );
  }

  static ({String apiKey, String appId}) get _platformValues {
    if (kIsWeb) return (apiKey: webApiKey, appId: webAppId);
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS => (apiKey: iosApiKey, appId: iosAppId),
      _ => (apiKey: androidApiKey, appId: androidAppId),
    };
  }
}
