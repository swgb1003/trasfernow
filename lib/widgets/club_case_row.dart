import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/transfer_case.dart';

enum ClubCaseRowMode { inbound, outbound, completed }

/// A row on the club page (IN / OUT / COMPLETED tabs). See SPEC.md §17.
class ClubCaseRow extends StatelessWidget {
  const ClubCaseRow({
    super.key,
    required this.transferCase,
    required this.mode,
    this.onTap,
  });

  final TransferCase transferCase;
  final ClubCaseRowMode mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = transferCase;
    final subtitle = switch (mode) {
      ClubCaseRowMode.inbound => '${c.fromClub} | ${c.playerPosition}',
      ClubCaseRowMode.outbound => '${c.toClub} | ${c.playerPosition}',
      ClubCaseRowMode.completed => c.route,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surface,
              child: Text(
                c.playerCountryFlag,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.playerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (mode == ClubCaseRowMode.completed)
              const Icon(Icons.check_circle, color: AppColors.official, size: 20)
            else
              Text(
                '${c.probability}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: c.status.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
