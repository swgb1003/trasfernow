import 'package:flutter/material.dart';

import '../models/transfer_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TransferStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${status.emoji} ${status.englishLabel}',
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
