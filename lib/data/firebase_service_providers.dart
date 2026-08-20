import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_messaging_service.dart';
import 'account_service.dart';
import 'user_preferences_repository.dart';

/// Overridden by `main()` after Firebase has initialized successfully.
/// Null keeps local development and widget tests on the dummy repository.
final firebaseFirestoreProvider = Provider<FirebaseFirestore?>((ref) => null);

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) => null);

/// Reacts to anonymous-to-Google account linking and existing-account sign-in.
/// See SPEC.md §13-§15, §24, §36.
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth?.userChanges() ?? Stream<User?>.value(null);
});

final accountIdentityProvider = Provider<AccountIdentity?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final streamedUser = ref.watch(firebaseUserProvider).asData?.value;
  final user = streamedUser ?? auth?.currentUser;
  if (user == null) return null;

  UserInfo? googleProfile;
  for (final provider in user.providerData) {
    if (provider.providerId == GoogleAuthProvider.PROVIDER_ID) {
      googleProfile = provider;
      break;
    }
  }
  return AccountIdentity(
    uid: user.uid,
    isAnonymous: user.isAnonymous,
    isGoogleLinked: googleProfile != null,
    displayName: user.displayName ?? googleProfile?.displayName,
    email: user.email ?? googleProfile?.email,
    photoUrl: user.photoURL ?? googleProfile?.photoURL,
  );
});

final accountServiceProvider = Provider<AccountService?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) return null;
  return FirebaseAccountService(auth: auth);
});

final accountLinkControllerProvider =
    StateNotifierProvider<AccountLinkController, AccountLinkState>(
      (ref) => AccountLinkController(ref.watch(accountServiceProvider)),
    );

final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService?>(
  (ref) => null,
);

/// Null in widget tests or local fallback mode. Once Firebase Auth is ready,
/// private preferences are stored below the current anonymous/permanent UID.
final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository?>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final userId =
      ref.watch(firebaseUserProvider).asData?.value?.uid ??
      auth?.currentUser?.uid;
  if (firestore == null || userId == null) return null;
  return FirestoreUserPreferencesRepository(
    firestore: firestore,
    userId: userId,
  );
});
