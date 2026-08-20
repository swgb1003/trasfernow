import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_messaging_service.dart';
import 'user_preferences_repository.dart';

/// Overridden by `main()` after Firebase has initialized successfully.
/// Null keeps local development and widget tests on the dummy repository.
final firebaseFirestoreProvider = Provider<FirebaseFirestore?>((ref) => null);

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) => null);

final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService?>(
  (ref) => null,
);

/// Null in widget tests or local fallback mode. Once Firebase Auth is ready,
/// private preferences are stored below the current anonymous/permanent UID.
final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository?>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userId = ref.watch(firebaseAuthProvider)?.currentUser?.uid;
  if (firestore == null || userId == null) return null;
  return FirestoreUserPreferencesRepository(
    firestore: firestore,
    userId: userId,
  );
});
