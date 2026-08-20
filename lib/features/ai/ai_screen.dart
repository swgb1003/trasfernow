import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/ai_reporter_engine.dart';
import '../../data/transfer_case_providers.dart';
import 'chat_message.dart';
import '../../widgets/async_content_state.dart';

/// AI REPORTER chat UI. See SPEC.md §10 AI移籍記者 / 画面09.
///
/// Responses come from [AiReporterEngine], a rule-based matcher over the
/// dummy dataset — not a real LLM call. See that file's doc comment for why.
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'こんにちは!移籍市場について何でも質問してください!',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  static const _suggestions = [
    '今日Chelseaで何か動いた?',
    '今日一番デカい移籍ニュースは?',
    'Arsenalが狙っているFW教えて',
    'この移籍って本当にありそう?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final cases = ref.read(transferCasesProvider).asData?.value;
    if (cases == null) return;
    final engine = AiReporterEngine(cases);

    setState(() {
      _messages.add(
        ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()),
      );
      _messages.add(
        ChatMessage(
          text: engine.answer(trimmed),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(transferCasesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [Text('AI REPORTER'), SizedBox(width: 8), _BetaTag()],
        ),
      ),
      body: casesAsync.when(
        loading: () => const AsyncContentState.loading(),
        error:
            (error, _) => AsyncContentState.error(
              error: error,
              onRetry: () => ref.invalidate(transferCasesProvider),
            ),
        data:
            (_) => Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length,
                    itemBuilder:
                        (context, index) =>
                            _MessageBubble(message: _messages[index]),
                  ),
                ),
                if (_messages.length <= 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _suggestions)
                          ActionChip(
                            label: Text(
                              s,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.card,
                            side: const BorderSide(color: AppColors.cardBorder),
                            onPressed: () => _send(s),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                _InputBar(controller: _controller, onSend: _send),
              ],
            ),
      ),
    );
  }
}

class _BetaTag extends StatelessWidget {
  const _BetaTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        'BETA',
        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.breaking : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
          border: isUser ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSend,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '質問を入力してください...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => onSend(controller.text),
            icon: const Icon(Icons.send_rounded, size: 18),
            style: IconButton.styleFrom(backgroundColor: AppColors.breaking),
          ),
        ],
      ),
    );
  }
}
