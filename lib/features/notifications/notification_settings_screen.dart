import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/favorites_provider.dart';
import '../../data/firebase_service_providers.dart';
import '../../data/notification_service.dart';
import '../../data/notification_settings_provider.dart';
import '../../data/transfer_case_providers.dart';
import '../../models/transfer_case.dart';
import '../../models/transfer_status.dart';

/// 通知設定. See SPEC.md §15 プッシュ通知 / 画面10 MY.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Ask for OS permission once, when the user actually opens notification
    // settings, rather than immediately on app launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final remote = ref.read(firebaseMessagingServiceProvider);
      if (remote != null) {
        unawaited(remote.requestPermission());
        unawaited(remote.syncTopics(ref.read(notificationSettingsProvider)));
      } else {
        unawaited(NotificationService.instance.requestPermission());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('通知設定')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader('通知する種類'),
          SwitchListTile(
            value: settings.breaking,
            onChanged: (value) {
              notifier.setBreaking(value);
              _syncRemoteTopics();
            },
            activeColor: AppColors.breaking,
            title: const Text('🔥 BREAKING'),
            subtitle: const Text('速報が入ったとき'),
          ),
          SwitchListTile(
            value: settings.agreement,
            onChanged: (value) {
              notifier.setAgreement(value);
              _syncRemoteTopics();
            },
            activeColor: AppColors.agreement,
            title: const Text('🤝 AGREEMENT'),
            subtitle: const Text('個人合意など、成立間近になったとき'),
          ),
          SwitchListTile(
            value: settings.official,
            onChanged: (value) {
              notifier.setOfficial(value);
              _syncRemoteTopics();
            },
            activeColor: AppColors.official,
            title: const Text('✅ OFFICIAL'),
            subtitle: const Text('正式発表されたとき'),
          ),
          const Divider(height: 32),
          const _SectionHeader('通知対象'),
          SwitchListTile(
            value: settings.followedOnly,
            onChanged: notifier.setFollowedOnly,
            activeColor: AppColors.breaking,
            title: const Text('お気に入りのみ通知'),
            subtitle: const Text('お気に入りクラブ・選手に関係する案件だけ通知する'),
          ),
          const Divider(height: 32),
          const _SectionHeader('通知をテスト'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '下のボタンは端末内テストです。Firebase接続時は、選択した種類のプッシュ通知も受信します。',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          _TestNotificationButton(
            enabled: settings.breaking,
            label: '🔥 BREAKINGを送る',
            color: AppColors.breaking,
            pick: (cases) => cases.isEmpty ? null : cases.first,
            send: NotificationService.instance.notifyBreaking,
          ),
          _TestNotificationButton(
            enabled: settings.agreement,
            label: '🤝 AGREEMENTを送る',
            color: AppColors.agreement,
            pick: (cases) {
              final candidates =
                  cases
                      .where((c) => c.status != TransferStatus.official)
                      .toList()
                    ..sort((a, b) => b.probability.compareTo(a.probability));
              return candidates.isEmpty ? null : candidates.first;
            },
            send: NotificationService.instance.notifyAgreement,
          ),
          _TestNotificationButton(
            enabled: settings.official,
            label: '✅ OFFICIALを送る',
            color: AppColors.official,
            pick: (cases) {
              final candidates =
                  cases
                      .where((c) => c.status == TransferStatus.official)
                      .toList();
              return candidates.isEmpty ? null : candidates.first;
            },
            send: NotificationService.instance.notifyOfficial,
          ),
        ],
      ),
    );
  }

  void _syncRemoteTopics() {
    final remote = ref.read(firebaseMessagingServiceProvider);
    if (remote == null) return;
    unawaited(remote.syncTopics(ref.read(notificationSettingsProvider)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}

class _TestNotificationButton extends ConsumerWidget {
  const _TestNotificationButton({
    required this.enabled,
    required this.label,
    required this.color,
    required this.pick,
    required this.send,
  });

  final bool enabled;
  final String label;
  final Color color;
  final TransferCase? Function(List<TransferCase> cases) pick;
  final Future<bool> Function(TransferCase) send;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: enabled ? () => _handleTap(context, ref) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: enabled ? color : AppColors.cardBorder),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final favorites = ref.read(favoritesProvider);
    final followedOnly = ref.read(notificationSettingsProvider).followedOnly;
    late List<TransferCase> cases;
    try {
      cases = await ref.read(transferCasesProvider.future);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('移籍情報を読み込めませんでした')));
      return;
    }

    if (followedOnly) {
      cases =
          cases
              .where(
                (c) =>
                    favorites.clubs.contains(c.fromClub.name) ||
                    favorites.clubs.contains(c.toClub.name) ||
                    favorites.playerCaseIds.contains(c.id),
              )
              .toList();
    }

    final target = pick(cases);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (target == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('該当する案件がありません(お気に入り設定を確認してください)')),
      );
      return;
    }

    final sent = await send(target);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sent ? '通知を送信しました: ${target.playerName}' : '通知の送信に失敗しました',
        ),
      ),
    );
  }
}
