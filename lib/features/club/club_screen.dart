import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/favorites_provider.dart';
import '../../data/transfer_case_providers.dart';
import '../../models/transfer_case.dart';
import '../../models/transfer_status.dart';
import '../../widgets/club_case_row.dart';

/// クラブページ: IN / OUT / COMPLETED. See SPEC.md §17, 画面07.
class ClubScreen extends ConsumerStatefulWidget {
  const ClubScreen({super.key, required this.clubName});

  final String clubName;

  @override
  ConsumerState<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends ConsumerState<ClubScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(transferCasesProvider);
    final club = widget.clubName;

    final inCandidates = cases
        .where((c) => c.toClub == club && c.status != TransferStatus.official)
        .toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));
    final outCandidates = cases
        .where(
          (c) => c.fromClub == club && c.status != TransferStatus.official,
        )
        .toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));
    final completed = cases
        .where(
          (c) =>
              (c.toClub == club || c.fromClub == club) &&
              c.status == TransferStatus.official,
        )
        .toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    final tabs = [
      ('IN', inCandidates, ClubCaseRowMode.inbound),
      ('OUT', outCandidates, ClubCaseRowMode.outbound),
      ('COMPLETED', completed, ClubCaseRowMode.completed),
    ];

    final isFavorite = ref.watch(
      favoritesProvider.select((s) => s.clubs.contains(club)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(club),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? AppColors.negotiation : null,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggleClub(club),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = i == _tabIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = i),
                    child: Column(
                      children: [
                        Text(
                          '${tabs[i].$1} (${tabs[i].$2.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2,
                          width: 28,
                          color:
                              selected ? AppColors.breaking : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _TabBody(entry: tabs[_tabIndex])),
        ],
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.entry});

  final (String, List<TransferCase>, ClubCaseRowMode) entry;

  @override
  Widget build(BuildContext context) {
    final (_, cases, mode) = entry;

    if (cases.isEmpty) {
      return const Center(
        child: Text(
          '現在該当する案件はありません',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cases.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => ClubCaseRow(
        transferCase: cases[i],
        mode: mode,
        onTap: () => context.push('/case/${cases[i].id}'),
      ),
    );
  }
}
