import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/transfer_case.dart';

/// A compact ranked row used on the MARKET screen (TRENDING / RANKINGS).
class RankingTile extends StatelessWidget {
  const RankingTile({
    super.key,
    required this.rank,
    required this.transferCase,
    required this.trailingLabel,
    required this.trailingColor,
    this.onTap,
  });

  final int rank;
  final TransferCase transferCase;
  final String trailingLabel;
  final Color trailingColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: rank <= 3 ? AppColors.breaking : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface,
              child: Text(
                transferCase.playerCountryFlag,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transferCase.playerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transferCase.route,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              trailingLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: trailingColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
