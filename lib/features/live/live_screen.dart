import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/transfer_case_providers.dart';
import '../../widgets/transfer_case_card.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  int _tabIndex = 0;
  static const _tabs = ['ALL', 'FOLLOWING', 'MY CLUBS'];

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(transferCasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LIVE',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = i == _tabIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = i),
                    child: Column(
                      children: [
                        Text(
                          _tabs[i],
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2,
                          width: 28,
                          color: selected
                              ? AppColors.breaking
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final c = cases[index];
                return TransferCaseCard(
                  transferCase: c,
                  isBreaking: index == 0,
                  onTap: () => context.push('/case/${c.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
