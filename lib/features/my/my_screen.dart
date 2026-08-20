import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/account_service.dart';
import '../../data/firebase_service_providers.dart';
import '../../data/favorites_provider.dart';
import '../../data/club_catalog.dart';
import '../../data/transfer_case_providers.dart';
import '../../models/transfer_case.dart';
import '../../widgets/entity_image.dart';
import '../../widgets/async_content_state.dart';

/// MY画面: お気に入りクラブ / お気に入り選手の管理. See SPEC.md §13, §14, 画面10.
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final casesAsync = ref.watch(transferCasesProvider);
    final watchCount = favorites.clubs.length + favorites.playerCaseIds.length;

    return Scaffold(
      appBar: AppBar(title: const Text('MY')),
      body: casesAsync.when(
        loading: () => const AsyncContentState.loading(),
        error:
            (error, _) => AsyncContentState.error(
              error: error,
              onRetry: () => ref.invalidate(transferCasesProvider),
            ),
        data: (cases) {
          final favoritePlayers =
              cases
                  .where((c) => favorites.playerCaseIds.contains(c.id))
                  .toList();
          return ListView(
            key: const ValueKey('my-content-list'),
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
                      onTap:
                          () => context.push(
                            '/club/${Uri.encodeComponent(club)}',
                          ),
                      onRemove:
                          () => ref
                              .read(favoritesProvider.notifier)
                              .toggleClub(club),
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
                      onRemove:
                          () => ref
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
          );
        },
      ),
    );
  }
}

void _showAddClubSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (context) => _AddPickerSheet(
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
                  onChanged:
                      (_) =>
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
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (context) => _AddPickerSheet(
          title: '選手を追加',
          builder: (context, ref) {
            final casesAsync = ref.watch(transferCasesProvider);
            final favorites = ref.watch(favoritesProvider);
            final cases = casesAsync.asData?.value;
            if (cases == null) {
              return const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ];
            }
            return [
              for (final c in cases)
                CheckboxListTile(
                  value: favorites.playerCaseIds.contains(c.id),
                  title: Text(c.playerName),
                  subtitle: Text(c.route),
                  activeColor: AppColors.breaking,
                  onChanged:
                      (_) => ref
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
                builder:
                    (context, ref, _) => ListView(
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

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(accountIdentityProvider);
    final linkState = ref.watch(accountLinkControllerProvider);
    final linked = identity?.isGoogleLinked ?? false;
    final displayName =
        linked && (identity?.displayName?.trim().isNotEmpty ?? false)
            ? identity!.displayName!.trim()
            : linked
            ? 'Googleユーザー'
            : 'ゲストユーザー';
    final subtitle =
        linked
            ? (identity?.email ?? 'Googleアカウントと同期中')
            : 'お気に入りをGoogleで安全に引き継げます';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: linked ? AppColors.accentLime : AppColors.cardBorder,
        ),
        boxShadow: [
          if (linked)
            BoxShadow(
              color: AppColors.accentLimeGlow.withValues(alpha: 0.08),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AccountAvatar(identity: identity),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AccountBadge(linked: linked),
            ],
          ),
          if (!linked) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('google-link-button'),
                onPressed:
                    linkState.isLoading
                        ? null
                        : () => _linkGoogle(context, ref),
                icon:
                    linkState.isLoading
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const _GoogleMark(),
                label: Text(
                  linkState.isLoading ? 'Googleアカウントを確認中…' : 'Googleでデータを引き継ぐ',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.textSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '課金なし・お気に入りと通知設定を端末変更後も復元',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _linkGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final result =
          await ref
              .read(accountLinkControllerProvider.notifier)
              .linkGoogleAccount();
      if (!context.mounted) return;
      final message = switch (result) {
        GoogleAccountLinkResult.linkedCurrentUser =>
          'Googleアカウントに連携しました。データを引き継げます。',
        GoogleAccountLinkResult.signedIntoExistingUser =>
          '既存アカウントにログインし、お気に入りを統合しました。',
        GoogleAccountLinkResult.alreadyLinked => 'このGoogleアカウントは連携済みです。',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.official),
      );
    } on AccountLinkException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.userMessage),
          backgroundColor:
              error.isCancellation ? AppColors.card : AppColors.breaking,
        ),
      );
    }
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.identity});

  final AccountIdentity? identity;

  @override
  Widget build(BuildContext context) {
    final photoUrl = identity?.photoUrl;
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color:
              identity?.isGoogleLinked ?? false
                  ? AppColors.accentLime
                  : AppColors.cardBorder,
        ),
      ),
      child:
          photoUrl != null && photoUrl.isNotEmpty
              ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _AccountFallbackIcon(),
              )
              : const _AccountFallbackIcon(),
    );
  }
}

class _AccountFallbackIcon extends StatelessWidget {
  const _AccountFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person, color: AppColors.textSecondary, size: 28);
  }
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({required this.linked});

  final bool linked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: linked ? AppColors.accentLime : AppColors.cardBorder,
        ),
      ),
      child: Text(
        linked ? 'SYNCED' : 'GUEST',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
          color: linked ? AppColors.accentLime : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: AppColors.rumour,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
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
    final clubDetails = ClubCatalog.findByName(club);
    return SizedBox(
      width: 64,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (clubDetails != null)
                  ClubCrest(club: clubDetails, size: 52, circular: true)
                else
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.card,
                    child: Text(club.isNotEmpty ? club[0] : '?'),
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
                PlayerAvatar(transferCase: transferCase, radius: 26),
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
