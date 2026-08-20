import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Shared loading/error treatment for repository-backed screens.
class AsyncContentState extends StatelessWidget {
  const AsyncContentState.loading({super.key}) : error = null, onRetry = null;

  const AsyncContentState.error({
    super.key,
    required Object this.error,
    required VoidCallback this.onRetry,
  });

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.accentCyan,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.breaking.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.breaking,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '移籍情報を読み込めませんでした',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              '通信状況を確認して、もう一度お試しください。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('retry-transfer-cases'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}
