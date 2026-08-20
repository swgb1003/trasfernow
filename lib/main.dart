import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'core/config/firebase_config.dart';
import 'data/firebase_messaging_service.dart';
import 'data/firebase_service_providers.dart';
import 'data/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  FirebaseFirestore? firestore;
  FirebaseAuth? auth;
  FirebaseMessagingService? messagingService;

  try {
    if (FirebaseConfig.isConfigured) {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatformOptions,
      );
    } else {
      // Android reads the non-secret app identifiers generated from
      // android/app/google-services.json by the Google Services plugin.
      await Firebase.initializeApp();
    }

    auth = FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously();

    firestore = FirebaseFirestore.instance;
    messagingService = FirebaseMessagingService.instance;
    await messagingService.initialize(
      firestore: firestore,
      userId: auth.currentUser!.uid,
    );
  } catch (error) {
    firestore = null;
    auth = null;
    messagingService = null;
    debugPrint('Firebase initialization failed; using dummy data: $error');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseFirestoreProvider.overrideWithValue(firestore),
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseMessagingServiceProvider.overrideWithValue(messagingService),
      ],
      child: const TransferNowApp(),
    ),
  );
}
