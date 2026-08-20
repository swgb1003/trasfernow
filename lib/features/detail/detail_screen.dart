import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/relative_time.dart';
import '../../core/theme/app_colors.dart';
import '../../data/favorites_provider.dart';
import '../../data/transfer_case_providers.dart';
import '../../models/transfer_case.dart';
import '../../models/transfer_status.dart';
import '../../widgets/ai_summary_card.dart';
import '../../widgets/official_reveal_overlay.dart';
import '../../widgets/probability_gauge.dart';
import '../../widgets/status_badge.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool? _showOfficialReveal;

  @override
  Widget build(BuildContext context) {
    final transferCase = ref.watch(transferCaseByIdProvider(widget.caseId));

    if (transferCase == null) {
      return const Scaffold(body: Center(child: Text('案件が見つかりません')));
    }

    // Only ever decided once per case, on the first build — later status
    // changes don't retroactively pop the celebration back up.
    _showOfficialReveal ??= transferCase.status == TransferStatus.official;

    return Scaffold(
      body: Stack(
        children: [
          _DetailContent(transferCase: transferCase),
          if (_showOfficialReveal == true)
            OfficialRevealOverlay(
              playerName: transferCase.playerName,
              fromClub: transferCase.fromClub,
              toClub: transferCase.toClub,
              onFinished: () => setState(() => _showOfficialReveal = false),
            ),
        ],
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.transferCase});

  final TransferCase transferCase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((s) => s.playerCaseIds.contains(transferCase.id)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(transferCase.playerName),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? AppColors.negotiation : null,
            ),
            onPressed: () => ref
                .read(favoritesProvider.notifier)
                .togglePlayerCase(transferCase.id),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        key: const ValueKey('detail-content-list'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ClubRoute(transferCase: transferCase),
          const SizedBox(height: 24),
          Center(
            child: ProbabilityGauge(
              probability: transferCase.probability,
              color: transferCase.status.color,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              transferCase.probabilityLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatTile(
                label: '推定移籍金',
                value:
                    '€${transferCase.estimatedFeeMillionsEur.toStringAsFixed(0)}M',
              ),
              _StatTile(
                label: '現在のステータス',
                value: '${transferCase.status.emoji} ${transferCase.status.label}',
              ),
              _StatTile(
                label: '最終更新',
                value: relativeTimeLabel(transferCase.lastUpdated),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            '移籍タイムライン',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _Timeline(events: transferCase.timeline),
          const SizedBox(height: 28),
          AiSummaryCard(transferCase: transferCase),
          const SizedBox(height: 28),
          Text(
            '情報源(報道数:${transferCase.sources.length})',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: transferCase.sources
                .map((s) => Chip(
                      label: Text(s.name),
                      backgroundColor: AppColors.card,
                      side: const BorderSide(color: AppColors.cardBorder),
                      labelStyle: const TextStyle(fontSize: 12),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ClubRoute extends StatelessWidget {
  const _ClubRoute({required this.transferCase});

  final TransferCase transferCase;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ClubBadge(name: transferCase.fromClub),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.arrow_forward, color: AppColors.textMuted),
        ),
        _ClubBadge(name: transferCase.toClub, highlighted: true),
      ],
    );
  }
}

class _ClubBadge extends StatelessWidget {
  const _ClubBadge({required this.name, this.highlighted = false});

  final String name;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/club/${Uri.encodeComponent(name)}'),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: highlighted
                ? AppColors.breaking.withValues(alpha: 0.15)
                : AppColors.surface,
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color:
                    highlighted ? AppColors.breaking : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Timeline with a cascading "light travels down as status progresses"
/// reveal on entry, plus a soft pulsing glow on the current (latest) status
/// dot. See SPEC.md §22 アニメーション — ステータス更新.
class _Timeline extends StatefulWidget {
  const _Timeline({required this.events});

  final List<TimelineEvent> events;

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final n = widget.events.length;
    _revealController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 450 + n * 320),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final n = events.length;

    return Column(
      children: List.generate(n, (i) {
        final event = events[i];
        final isLast = i == n - 1;

        final dotInterval = Interval(
          (n <= 1 ? 0.0 : i / n).clamp(0.0, 1.0),
          (n <= 1 ? 1.0 : (i + 0.6) / n).clamp(0.0, 1.0),
          curve: Curves.easeOutBack,
        );
        final dotFadeInterval = Interval(
          (n <= 1 ? 0.0 : i / n).clamp(0.0, 1.0),
          (n <= 1 ? 1.0 : (i + 0.6) / n).clamp(0.0, 1.0),
        );
        final connectorInterval = Interval(
          (n <= 1 ? 0.0 : (i + 0.5) / n).clamp(0.0, 1.0),
          (n <= 1 ? 1.0 : (i + 1.4) / n).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        );

        final dotAnim = CurvedAnimation(
          parent: _revealController,
          curve: dotInterval,
        );
        final dotFade = CurvedAnimation(
          parent: _revealController,
          curve: dotFadeInterval,
        );
        final connectorAnim = CurvedAnimation(
          parent: _revealController,
          curve: connectorInterval,
        );

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([dotAnim, _pulseController]),
                    builder: (context, _) {
                      final pulse = isLast ? _pulseController.value : 0.0;
                      return Transform.scale(
                        scale: dotAnim.value,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: event.status.color,
                            boxShadow: isLast
                                ? [
                                    BoxShadow(
                                      color: event.status.color
                                          .withValues(alpha: 0.25 + pulse * 0.35),
                                      blurRadius: 4 + pulse * 10,
                                      spreadRadius: pulse * 3.5,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                  if (!isLast)
                    Expanded(
                      child: AnimatedBuilder(
                        animation: connectorAnim,
                        builder: (context, _) {
                          // A bright band sweeps from the top of the
                          // connector down to `t`, leaving a faint trail
                          // behind it — the "light travels down the
                          // timeline" effect, without needing a Stack
                          // (which can't report a finite intrinsic size
                          // inside the IntrinsicHeight row above).
                          final t = connectorAnim.value.clamp(0.0, 1.0);
                          final leadingEdge = (t - 0.18).clamp(0.0, 1.0);
                          return Container(
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  event.status.color.withValues(alpha: 0.15),
                                  event.status.color.withValues(alpha: 0.95),
                                  event.status.color.withValues(alpha: 0.15),
                                ],
                                stops: [leadingEdge, t, 1.0],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AnimatedBuilder(
                    animation: dotFade,
                    builder: (context, child) => Opacity(
                      opacity: dotFade.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - dotFade.value.clamp(0.0, 1.0)) * 8),
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dateLabel(event.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: event.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(event.description),
                        const SizedBox(height: 4),
                        Text(
                          event.source.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
