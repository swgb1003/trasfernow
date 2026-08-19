import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/relative_time.dart';
import '../../core/theme/app_colors.dart';
import '../../data/transfer_case_providers.dart';
import '../../models/transfer_case.dart';
import '../../widgets/probability_gauge.dart';
import '../../widgets/status_badge.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferCase = ref.watch(transferCaseByIdProvider(caseId));

    if (transferCase == null) {
      return const Scaffold(body: Center(child: Text('案件が見つかりません')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(transferCase.playerName),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.star_border),
          ),
        ],
      ),
      body: ListView(
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
                value: '€${transferCase.estimatedFeeMillionsEur.toStringAsFixed(0)}M',
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
          Text(
            '情報源（報道数：${transferCase.sources.length}）',
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
    return Column(
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
              color: highlighted ? AppColors.breaking : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
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

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (i) {
        final event = events[i];
        final isLast = i == events.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.status.color,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: event.status.color.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
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
            ],
          ),
        );
      }),
    );
  }
}
