import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 通知対象の設定. See SPEC.md §15「通知対象はユーザーが設定できる」.
/// In-memory only (no persistence yet — SPEC.md §36 開発方針).
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
  NotificationSettingsNotifier()
      : super(
          const NotificationSettingsState(
            breaking: true,
            agreement: true,
            official: true,
            followedOnly: false,
          ),
        );

  void setBreaking(bool value) => state = state.copyWith(breaking: value);
  void setAgreement(bool value) => state = state.copyWith(agreement: value);
  void setOfficial(bool value) => state = state.copyWith(official: value);
  void setFollowedOnly(bool value) =>
      state = state.copyWith(followedOnly: value);
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettingsState>(
  (ref) => NotificationSettingsNotifier(),
);
