import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/config/firebase_config.dart';
import 'notification_service.dart';
import 'notification_settings_provider.dart';

/// Entry point used by Android/iOS when an FCM message wakes a background
/// isolate. See SPEC.md §15, §36.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    if (FirebaseConfig.isConfigured) {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatformOptions,
      );
    } else {
      await Firebase.initializeApp();
    }
  }
}

/// Registers FCM tokens and mirrors category preferences to FCM topics.
/// Sending remains a trusted Cloud Functions/server responsibility.
class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final instance = FirebaseMessagingService._();

  FirebaseFirestore? _firestore;
  String? _userId;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  Future<void> initialize({
    required FirebaseFirestore firestore,
    required String userId,
  }) async {
    _firestore = firestore;
    _userId = userId;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      _persistToken,
      onError: (Object error) {
        debugPrint('FCM token refresh failed: $error');
      },
    );
    _messageSubscription ??= FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
    );

    await _saveCurrentToken();
  }

  Future<bool> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (allowed) await _saveCurrentToken();
      return allowed;
    } catch (error) {
      debugPrint('FCM permission request failed: $error');
      return false;
    }
  }

  Future<void> syncTopics(NotificationSettingsState settings) async {
    await Future.wait([
      _setTopic('transfer_breaking', settings.breaking),
      _setTopic('transfer_agreement', settings.agreement),
      _setTopic('transfer_official', settings.official),
    ]);
  }

  Future<void> _setTopic(String topic, bool enabled) async {
    try {
      if (enabled) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
    } catch (error) {
      debugPrint('FCM topic update failed for $topic: $error');
    }
  }

  Future<void> _saveCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) await _persistToken(token);
    } catch (error) {
      // iOS commonly has no FCM token until APNs permission is granted.
      debugPrint('FCM token is not available yet: $error');
    }
  }

  Future<void> _persistToken(String token) async {
    final firestore = _firestore;
    final userId = _userId;
    if (firestore == null || userId == null) return;

    try {
      final safeId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
      await firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(safeId)
          .set({
            'token': token,
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null || body == null) return;

    await NotificationService.instance.showRemote(
      title: title,
      body: body,
      category: message.data['category'] as String?,
    );
  }
}
