import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/favorites_provider.dart';
import '../../data/transfer_case_providers.dart';
import '../../models/transfer_case.dart';

/// MY画面: お気に入りクラブ / お気に入り選手の管理. See SPEC.md §13, §14, 画面10.
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final cases = ref.watch(transferCasesProvider);
    final favoritePlayers =
        cases.where((c) => favorites.playerCaseIds.contains(c.id)).toList();
    final watchCount = favorites.clubs.length + favorites.playerCaseIds.length;

    return Scaffold(
      appBar: AppBar(title: const Text('MY')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 28),
          _FavoritesSection(
            title: 'お気に入りクラブ',
            children: [
              for (final club in favorites.clubs)
                _ClubChip(
                  club: club,
                  onTap: () =>
                      context.push('/club/${Uri.encodeComponent(club)}'),
                  onRemove: () =>
                      ref.read(favoritesProvider.notifier).toggleClub(club),
                ),
              _AddChip(onTap: () => _showAddClubSheet(context)),
            ],
          ),
          const SizedBox(height: 24),
          _FavoritesSection(
            title: 'お気に入り選手',
            children: [
              for (final c in favoritePlayers)
                _PlayerChip(
                  transferCase: c,
                  onTap: () => context.push('/case/${c.id}'),
                  onRemove: () => ref
                      .read(favoritesProvider.notifier)
                      .togglePlayerCase(c.id),
                ),
              _AddChip(onTap: () => _showAddPlayerSheet(context)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 32),
          _MenuTile(
            icon: Icons.visibility_outlined,
            label: 'ウォッチリスト',
            trailingText: '$watchCount',
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: '通知設定',
            onTap: () => context.push('/notifications'),
          ),
          const _MenuTile(icon: Icons.settings_outlined, label: 'アプリ設定'),
          const _MenuTile(icon: Icons.help_outline, label: 'ヘルプ / お問い合わせ'),
        ],
      ),
    );
  }
}

void _showAddClubSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _AddPickerSheet(
      title: 'クラブを追加',
      builder: (context, ref) {
        final allClubs = ref.watch(allClubsProvider);
        final favorites = ref.watch(favoritesProvider);
        return [
          for (final club in allClubs)
            CheckboxListTile(
              value: favorites.clubs.contains(club),
              title: Text(club),
              activeColor: AppColors.breaking,
              onChanged: (_) =>
                  ref.read(favoritesProvider.notifier).toggleClub(club),
            ),
        ];
      },
    ),
  );
}

void _showAddPlayerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _AddPickerSheet(
      title: '選手を追加',
      builder: (context, ref) {
        final cases = ref.watch(transferCasesProvider);
        final favorites = ref.watch(favoritesProvider);
        return [
          for (final c in cases)
            CheckboxListTile(
              value: favorites.playerCaseIds.contains(c.id),
              title: Text(c.playerName),
              subtitle: Text(c.route),
              activeColor: AppColors.breaking,
              onChanged: (_) => ref
                  .read(favoritesProvider.notifier)
                  .togglePlayerCase(c.id),
            ),
        ];
      },
    ),
  );
}

class _AddPickerSheet extends StatelessWidget {
  const _AddPickerSheet({required this.title, required this.builder});

  final String title;
  final List<Widget> Function(BuildContext, WidgetRef) builder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // `isScrollControlled: true` on the sheet gives this Column a
            // real bounded height to work with, so `Flexible` can safely
            // hand the list whatever's left — unlike a hardcoded
            // MediaQuery-based max height, this can never overflow.
            Flexible(
              child: Consumer(
                builder: (context, ref, _) => ListView(
                  key: const ValueKey('add-picker-list'),
                  shrinkWrap: true,
                  children: builder(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.card,
          child: Icon(Icons.person, color: AppColors.textSecondary, size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Footy Lover',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              SizedBox(height: 2),
              Text(
                '@transfer_now',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Text(
            'PRO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.negotiation,
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => children[i],
          ),
        ),
      ],
    );
  }
}

class _ClubChip extends StatelessWidget {
  const _ClubChip({
    required this.club,
    required this.onTap,
    required this.onRemove,
  });

  final String club;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.card,
                  child: Text(
                    club.isNotEmpty ? club[0] : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: _RemoveBadge(
                    key: ValueKey('remove-club-$club'),
                    onTap: onRemove,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              club,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.transferCase,
    required this.onTap,
    required this.onRemove,
  });

  final TransferCase transferCase;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.card,
                  child: Text(
                    transferCase.playerCountryFlag,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: _RemoveBadge(
                    key: ValueKey('remove-player-${transferCase.id}'),
                    onTap: onRemove,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              transferCase.playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(Icons.add, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            const Text(
              '追加',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.breaking,
          border: Border.all(color: AppColors.background, width: 1.5),
        ),
        child: const Icon(Icons.close, size: 11, color: Colors.white),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.trailingText,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
      onTap: onTap,
    );
  }
}
