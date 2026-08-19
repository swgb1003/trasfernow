import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/transfer_case_providers.dart';
import '../../widgets/transfer_case_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(transferCasesProvider);
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? const []
        : cases.where((c) {
            return c.playerName.toLowerCase().contains(query) ||
                c.fromClub.toLowerCase().contains(query) ||
                c.toClub.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('SEARCH')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '選手・クラブ・リーグを検索',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (query.isEmpty)
              const Text(
                'トレンド選手',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              )
            else
              Text(
                '検索結果 ${results.length}件',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final c in (query.isEmpty ? cases : results))
                    TransferCaseCard(
                      transferCase: c,
                      onTap: () => context.push('/case/${c.id}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
