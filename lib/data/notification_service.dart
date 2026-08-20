import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/transfer_case.dart';

/// Wraps `flutter_local_notifications`. There is no backend yet (SPEC.md
/// §36 開発方針), so nothing actually pushes to this app — these are
/// user-triggered local notifications that simulate what a real push
/// (SPEC.md §15) would look like once a server exists to send them.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  /// Requests OS notification permission (Android 13+ / iOS). Safe to call
  /// repeatedly; returns false (rather than throwing) if the platform
  /// plugin isn't available, e.g. in the widget-test harness.
  Future<bool> requestPermission() async {
    try {
      await _ensureInitialized();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService.requestPermission failed: $e');
      return false;
    }
  }

  Future<bool> _show({
    required String channelId,
    required String channelName,
    required String title,
    required String body,
  }) async {
    try {
      await _ensureInitialized();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title,
        body,
        details,
      );
      return true;
    } catch (e) {
      debugPrint('NotificationService.show failed: $e');
      return false;
    }
  }

  /// 🔥 BREAKING — SPEC.md §15 例:「ChelseaがPLAYER Aへ正式オファー」
  Future<bool> notifyBreaking(TransferCase c) => _show(
        channelId: 'breaking',
        channelName: '速報 (BREAKING)',
        title: '🔥 BREAKING',
        body: '${c.playerName}: ${c.headline}',
      );

  /// 🤝 AGREEMENT — SPEC.md §15 例:「PLAYER BがArsenalと個人合意」
  Future<bool> notifyAgreement(TransferCase c) => _show(
        channelId: 'agreement',
        channelName: '合意 (AGREEMENT)',
        title: '🤝 AGREEMENT',
        body: '${c.playerName}が${c.toClub}と個人合意',
      );

  /// ✅ OFFICIAL — SPEC.md §15 例:「PLAYER CのManchester City加入が正式発表」
  Future<bool> notifyOfficial(TransferCase c) => _show(
        channelId: 'official',
        channelName: '正式発表 (OFFICIAL)',
        title: '✅ OFFICIAL',
        body: '${c.playerName}の${c.toClub}加入が正式発表',
      );
}
