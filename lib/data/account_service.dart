import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Minimal account data exposed to the MY screen.
/// See SPEC.md §13-§15, §24, §36.
class AccountIdentity {
  const AccountIdentity({
    required this.uid,
    required this.isAnonymous,
    required this.isGoogleLinked,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final bool isAnonymous;
  final bool isGoogleLinked;
  final String? displayName;
  final String? email;
  final String? photoUrl;
}

enum GoogleAccountLinkResult {
  linkedCurrentUser,
  signedIntoExistingUser,
  alreadyLinked,
}

class AccountLinkException implements Exception {
  const AccountLinkException(
    this.userMessage, {
    this.code,
    this.isCancellation = false,
  });

  final String userMessage;
  final String? code;
  final bool isCancellation;

  @override
  String toString() => 'AccountLinkException($code, $userMessage)';
}

abstract interface class AccountService {
  Future<GoogleAccountLinkResult> linkGoogleAccount();
}

/// Links the existing anonymous Firebase user to Google whenever possible, so
/// the UID (and therefore private Firestore data) stays unchanged. If that
/// Google credential already belongs to an account, it signs into that account;
/// the preferences layer then merges this device's favorites into it.
/// See SPEC.md §13-§15, §24, §36.
class FirebaseAccountService implements AccountService {
  FirebaseAccountService({
    required FirebaseAuth auth,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  static Future<void>? _googleInitialization;

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  @override
  Future<GoogleAccountLinkResult> linkGoogleAccount() async {
    try {
      await _ensureGoogleInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AccountLinkException(
          'この端末ではGoogleログインを利用できません。',
          code: 'unsupported-platform',
        );
      }

      // The plugin recommends signing out before an interactive account pick,
      // which also lets the user choose a different Google account.
      await _googleSignIn.signOut();
      final googleAccount = await _googleSignIn.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AccountLinkException(
          'Googleからログイン情報を取得できませんでした。もう一度お試しください。',
          code: 'missing-id-token',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final currentUser =
          _auth.currentUser ?? (await _auth.signInAnonymously()).user;
      if (currentUser == null) {
        throw const AccountLinkException(
          'アカウントを準備できませんでした。通信状態を確認してください。',
          code: 'missing-firebase-user',
        );
      }

      if (currentUser.providerData.any(
        (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
      )) {
        return GoogleAccountLinkResult.alreadyLinked;
      }

      try {
        await currentUser.linkWithCredential(credential);
        return GoogleAccountLinkResult.linkedCurrentUser;
      } on FirebaseAuthException catch (error) {
        if (error.code == 'provider-already-linked') {
          return GoogleAccountLinkResult.alreadyLinked;
        }
        if (error.code == 'credential-already-in-use' ||
            error.code == 'email-already-in-use') {
          await _auth.signInWithCredential(credential);
          return GoogleAccountLinkResult.signedIntoExistingUser;
        }
        throw _mapFirebaseError(error);
      }
    } on AccountLinkException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw _mapGoogleError(error);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseError(error);
    } catch (_) {
      throw const AccountLinkException(
        'Googleアカウントとの連携に失敗しました。しばらくしてからお試しください。',
        code: 'unknown',
      );
    }
  }

  AccountLinkException _mapGoogleError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return AccountLinkException(
          'Googleログインをキャンセルしました。',
          code: error.code.name,
          isCancellation: true,
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return AccountLinkException(
          'Googleログインの設定が完了していません。Firebaseの設定を確認してください。',
          code: error.code.name,
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return AccountLinkException(
          'Googleログイン画面を開けませんでした。アプリを再起動してください。',
          code: error.code.name,
        );
      default:
        return AccountLinkException(
          'Googleログインに失敗しました。もう一度お試しください。',
          code: error.code.name,
        );
    }
  }

  AccountLinkException _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return const AccountLinkException(
          '通信できませんでした。ネットワーク接続を確認してください。',
          code: 'network-request-failed',
        );
      case 'account-exists-with-different-credential':
        return const AccountLinkException(
          '同じメールアドレスが別のログイン方法で登録されています。',
          code: 'account-exists-with-different-credential',
        );
      case 'operation-not-allowed':
        return const AccountLinkException(
          'Firebase ConsoleでGoogleログインを有効にしてください。',
          code: 'operation-not-allowed',
        );
      case 'invalid-credential':
        return const AccountLinkException(
          'Googleのログイン情報を確認できませんでした。もう一度お試しください。',
          code: 'invalid-credential',
        );
      default:
        return AccountLinkException(
          'Googleアカウントとの連携に失敗しました。もう一度お試しください。',
          code: error.code,
        );
    }
  }
}

class AccountLinkState {
  const AccountLinkState({this.isLoading = false});

  final bool isLoading;
}

class AccountLinkController extends StateNotifier<AccountLinkState> {
  AccountLinkController(this._service) : super(const AccountLinkState());

  final AccountService? _service;

  Future<GoogleAccountLinkResult> linkGoogleAccount() async {
    if (state.isLoading) {
      throw const AccountLinkException(
        'アカウントを連携しています。少しお待ちください。',
        code: 'already-in-progress',
      );
    }
    final service = _service;
    if (service == null) {
      throw const AccountLinkException(
        'Firebaseに接続できていません。アプリを再起動してください。',
        code: 'firebase-unavailable',
      );
    }

    state = const AccountLinkState(isLoading: true);
    try {
      return await service.linkGoogleAccount();
    } finally {
      if (mounted) state = const AccountLinkState();
    }
  }
}
