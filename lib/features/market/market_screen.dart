import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/transfer_case_providers.dart';
import '../../models/transfer_case.dart';
import '../../models/transfer_status.dart';
import '../../widgets/ranking_tile.dart';

/// MARKET dashboard. See SPEC.md §18 移籍市場ダッシュボード / 画面08.
///
/// All figures here are computed live from the 12-item dummy dataset
/// (SPEC.md §36 開発方針) rather than the larger illustrative numbers shown
/// in the original mockup, so what's on screen always matches what you can
/// tap into.
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  int _tabIndex = 0;
  static const _tabs = ['OVERVIEW', 'TRENDING', 'RANKINGS'];

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(transferCasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MARKET')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = i == _tabIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = i),
                    child: Column(
                      children: [
                        Text(
                          _tabs[i],
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
          Expanded(
            child: switch (_tabIndex) {
              0 => _OverviewView(cases: cases),
              1 => _RankedListView(
                  cases: [...cases]
                    ..sort((a, b) => b.probability.compareTo(a.probability)),
                  trailingBuilder: (c) => ('${c.probability}%', c.status.color),
                ),
              _ => _RankedListView(
                  cases: [...cases]..sort(
                      (a, b) => b.estimatedFeeMillionsEur
                          .compareTo(a.estimatedFeeMillionsEur),
                    ),
                  trailingBuilder: (c) => (
                    '€${c.estimatedFeeMillionsEur.toStringAsFixed(0)}M',
                    AppColors.textPrimary,
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView({required this.cases});

  final List<TransferCase> cases;

  @override
  Widget build(BuildContext context) {
    final earlyStage = cases
        .where((c) =>
            c.status == TransferStatus.rumour ||
            c.status == TransferStatus.interest)
        .length;
    final inNegotiation = cases
        .where((c) =>
            c.status == TransferStatus.contact ||
            c.status == TransferStatus.negotiation ||
            c.status == TransferStatus.bid)
        .length;
    final nearAgreement = cases
        .where((c) =>
            c.status == TransferStatus.agreement ||
            c.status == TransferStatus.finalStage)
        .length;
    final official =
        cases.where((c) => c.status == TransferStatus.official).length;

    final trending = [...cases]
      ..sort((a, b) => b.probability.compareTo(a.probability));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          "TODAY'S MARKET",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _StatCard(
              label: '新規/初期段階',
              value: '$earlyStage',
              color: AppColors.rumour,
            ),
            _StatCard(
              label: '交渉進展中',
              value: '$inNegotiation',
              color: AppColors.negotiation,
            ),
            _StatCard(
              label: '合意間近',
              value: '$nearAgreement',
              color: AppColors.agreement,
            ),
            _StatCard(
              label: 'OFFICIAL',
              value: '$official',
              color: AppColors.official,
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Row(
          children: [
            Text('🔥', style: TextStyle(fontSize: 14)),
            SizedBox(width: 6),
            Text(
              'TRENDING NOW',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (var i = 0; i < trending.length && i < 5; i++) ...[
                  RankingTile(
                    rank: i + 1,
                    transferCase: trending[i],
                    trailingLabel: '${trending[i].probability}%',
                    trailingColor: trending[i].status.color,
                    onTap: () => context.push('/case/${trending[i].id}'),
                  ),
                  if (i < 4 && i < trending.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankedListView extends StatelessWidget {
  const _RankedListView({
    required this.cases,
    required this.trailingBuilder,
  });

  final List<TransferCase> cases;
  final (String, Color) Function(TransferCase) trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: cases.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final (label, color) = trailingBuilder(cases[index]);
        return RankingTile(
          rank: index + 1,
          transferCase: cases[index],
          trailingLabel: label,
          trailingColor: color,
          onTap: () => context.push('/case/${cases[index].id}'),
        );
      },
    );
  }
}
