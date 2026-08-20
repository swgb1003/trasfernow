import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

/// 通知対象の設定. See SPEC.md §15「通知対象はユーザーが設定できる」.
/// Persisted locally via [SharedPreferences] (no backend yet — SPEC.md §36
/// 開発方針).
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
  NotificationSettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _breakingKey = 'notifications.breaking';
  static const _agreementKey = 'notifications.agreement';
  static const _officialKey = 'notifications.official';
  static const _followedOnlyKey = 'notifications.followedOnly';

  static NotificationSettingsState _load(SharedPreferences prefs) {
    return NotificationSettingsState(
      breaking: prefs.getBool(_breakingKey) ?? true,
      agreement: prefs.getBool(_agreementKey) ?? true,
      official: prefs.getBool(_officialKey) ?? true,
      followedOnly: prefs.getBool(_followedOnlyKey) ?? false,
    );
  }

  void setBreaking(bool value) {
    state = state.copyWith(breaking: value);
    _prefs.setBool(_breakingKey, value);
  }

  void setAgreement(bool value) {
    state = state.copyWith(agreement: value);
    _prefs.setBool(_agreementKey, value);
  }

  void setOfficial(bool value) {
    state = state.copyWith(official: value);
    _prefs.setBool(_officialKey, value);
  }

  void setFollowedOnly(bool value) {
    state = state.copyWith(followedOnly: value);
    _prefs.setBool(_followedOnlyKey, value);
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettingsState>(
  (ref) => NotificationSettingsNotifier(ref.watch(sharedPreferencesProvider)),
);
