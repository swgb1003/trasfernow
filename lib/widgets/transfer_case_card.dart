import 'package:flutter/material.dart';

import '../core/format/relative_time.dart';
import '../core/theme/app_colors.dart';
import '../models/transfer_case.dart';
import 'entity_image.dart';

/// A row in the LIVE feed / club IN-OUT lists. See SPEC.md §5.1, §17.
class TransferCaseCard extends StatelessWidget {
  const TransferCaseCard({
    super.key,
    required this.transferCase,
    this.isBreaking = false,
    this.onTap,
  });

  final TransferCase transferCase;
  final bool isBreaking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = transferCase.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isBreaking
                  ? AppColors.breaking.withValues(alpha: 0.6)
                  : AppColors.cardBorder,
          width: isBreaking ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBreaking)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.breaking,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🔥 BREAKING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        relativeTimeLabel(transferCase.lastUpdated),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlayerAvatar(transferCase: transferCase),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transferCase.playerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transferCase.route,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          transferCase.headline,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (!isBreaking) ...[
                          const SizedBox(height: 6),
                          Text(
                            relativeTimeLabel(transferCase.lastUpdated),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${transferCase.probability}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: status.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
