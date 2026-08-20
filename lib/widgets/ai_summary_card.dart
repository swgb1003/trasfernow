import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../data/ai_summary_engine.dart';
import '../models/transfer_case.dart';

/// AI要約カード. See SPEC.md §11 AIニュース要約 / 画面05.
class AiSummaryCard extends StatelessWidget {
  const AiSummaryCard({super.key, required this.transferCase});

  final TransferCase transferCase;

  @override
  Widget build(BuildContext context) {
    final summary = buildAiSummary(transferCase);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.negotiation),
              const SizedBox(width: 6),
              const Text(
                'AI SUMMARY',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: '現在の状況', text: summary.current),
          const SizedBox(height: 12),
          _SummaryRow(label: '推定移籍金', text: summary.fee),
          const SizedBox(height: 12),
          _SummaryRow(label: '次の動き', text: summary.nextMove),
          const SizedBox(height: 8),
          Text(
            '${transferCase.sources.length}件の情報源をもとにした推定です',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/ai'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'もっと詳しくAIに質問する',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }
}
