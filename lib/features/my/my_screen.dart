import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MY')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _MenuTile(icon: Icons.shield_outlined, label: 'お気に入りクラブ'),
          _MenuTile(icon: Icons.person_outline, label: 'お気に入り選手'),
          _MenuTile(icon: Icons.visibility_outlined, label: 'ウォッチリスト'),
          _MenuTile(icon: Icons.notifications_outlined, label: '通知設定'),
          _MenuTile(icon: Icons.settings_outlined, label: 'アプリ設定'),
          _MenuTile(icon: Icons.help_outline, label: 'ヘルプ / お問い合わせ'),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textMuted,
      ),
      onTap: () {},
    );
  }
}
