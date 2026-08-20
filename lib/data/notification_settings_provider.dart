import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service_providers.dart';
import 'shared_preferences_provider.dart';
import 'user_preferences_repository.dart';

/// 通知対象の設定. See SPEC.md §15「通知対象はユーザーが設定できる」.
/// Persisted locally via [SharedPreferences] and mirrored to the authenticated
/// user's Firestore preferences. FCM topic subscriptions are synchronized by
/// the app shell and notification screen.
class NotificationSettingsState {
  const NotificationSettingsState({
    required this.breaking,
    required this.agreement,
    required this.official,
    required this.followedOnly,
  });

  final bool breaking;
  final bool agreement;
  final bool official;

  /// 通知対象をお気に入りクラブ・選手に関係する案件のみに絞る.
  final bool followedOnly;

  NotificationSettingsState copyWith({
    bool? breaking,
    bool? agreement,
    bool? official,
    bool? followedOnly,
  }) {
    return NotificationSettingsState(
      breaking: breaking ?? this.breaking,
      agreement: agreement ?? this.agreement,
      official: official ?? this.official,
      followedOnly: followedOnly ?? this.followedOnly,
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier(this._prefs, this._cloud)
    : super(_load(_prefs)) {
    initializationComplete = _initializeCloud();
  }

  final SharedPreferences _prefs;
  final UserPreferencesRepository? _cloud;
  late final Future<void> initializationComplete;
  int _revision = 0;

  static const _breakingKey = 'notifications.breaking';
  static const _agreementKey = 'notifications.agreement';
  static const _officialKey = 'notifications.official';
  static const _followedOnlyKey = 'notifications.followedOnly';

  String get _syncMarkerKey => 'cloudSync.notifications.${_cloud!.userId}';

  String get _pendingKey => 'cloudSync.notifications.pending.${_cloud!.userId}';

  static NotificationSettingsState _load(SharedPreferences prefs) {
    return NotificationSettingsState(
      breaking: prefs.getBool(_breakingKey) ?? true,
      agreement: prefs.getBool(_agreementKey) ?? true,
      official: prefs.getBool(_officialKey) ?? true,
      followedOnly: prefs.getBool(_followedOnlyKey) ?? false,
    );
  }

  bool get _hasExplicitLocalData =>
      _prefs.containsKey(_breakingKey) ||
      _prefs.containsKey(_agreementKey) ||
      _prefs.containsKey(_officialKey) ||
      _prefs.containsKey(_followedOnlyKey);

  Future<void> _persistLocal(NotificationSettingsState value) async {
    await _prefs.setBool(_breakingKey, value.breaking);
    await _prefs.setBool(_agreementKey, value.agreement);
    await _prefs.setBool(_officialKey, value.official);
    await _prefs.setBool(_followedOnlyKey, value.followedOnly);
  }

  Future<void> _initializeCloud() async {
    final cloud = _cloud;
    if (cloud == null) return;

    final revisionBeforeLoad = _revision;
    final synchronizedBefore = _prefs.getBool(_syncMarkerKey) ?? false;
    final hasPendingChanges =
        _prefs.getBool(_pendingKey) ??
        (!synchronizedBefore && _hasExplicitLocalData);

    if (hasPendingChanges) {
      await _pushCloud();
      return;
    }

    try {
      final remote = await cloud.loadNotifications();
      if (!mounted) return;
      if (_revision != revisionBeforeLoad) {
        await _pushCloud();
        return;
      }
      if (remote == null) {
        await _pushCloud();
        return;
      }

      state = NotificationSettingsState(
        breaking: remote.breaking,
        agreement: remote.agreement,
        official: remote.official,
        followedOnly: remote.followedOnly,
      );
      await _persistLocal(state);
      await _markSynchronized();
    } catch (error) {
      debugPrint(
        'Notification cloud restore failed; keeping local data: $error',
      );
    }
  }

  Future<void> _pushCloud() async {
    final cloud = _cloud;
    if (cloud == null) return;
    final revision = _revision;
    final snapshot = NotificationPreferencesData(
      breaking: state.breaking,
      agreement: state.agreement,
      official: state.official,
      followedOnly: state.followedOnly,
    );
    await _prefs.setBool(_pendingKey, true);
    try {
      await cloud.saveNotifications(snapshot);
      if (revision == _revision) await _markSynchronized();
    } catch (error) {
      debugPrint(
        'Notification cloud sync failed; local changes are pending: $error',
      );
    }
  }

  Future<void> _markSynchronized() async {
    await _prefs.setBool(_syncMarkerKey, true);
    await _prefs.setBool(_pendingKey, false);
  }

  void _didChange() {
    _revision += 1;
    if (_cloud != null) unawaited(_prefs.setBool(_pendingKey, true));
    unawaited(_persistAndSync());
  }

  Future<void> _persistAndSync() async {
    await _persistLocal(state);
    await _pushCloud();
  }

  /// Explicit retry hook for lifecycle/resume integration and tests.
  Future<void> synchronize() => _pushCloud();

  void setBreaking(bool value) {
    state = state.copyWith(breaking: value);
    _didChange();
  }

  void setAgreement(bool value) {
    state = state.copyWith(agreement: value);
    _didChange();
  }

  void setOfficial(bool value) {
    state = state.copyWith(official: value);
    _didChange();
  }

  void setFollowedOnly(bool value) {
    state = state.copyWith(followedOnly: value);
    _didChange();
  }
}

final notificationSettingsProvider = StateNotifierProvider<
  NotificationSettingsNotifier,
  NotificationSettingsState
>(
  (ref) => NotificationSettingsNotifier(
    ref.watch(sharedPreferencesProvider),
    ref.watch(userPreferencesRepositoryProvider),
  ),
);
