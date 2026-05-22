import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/messaging_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/message_bubble.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? participantId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.participantId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _msgCounter = 0;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final clientMsgId = 'client-${DateTime.now().millisecondsSinceEpoch}-${_msgCounter++}';

    _controller.clear();
    FocusScope.of(context).unfocus();

    final notifier = ref.read(sendMessageProvider.notifier);
    await notifier.send(
      conversationId: widget.conversationId,
      content: content,
      clientMessageId: clientMsgId,
    );

    if (mounted) {
      ref.invalidate(messagesProvider(widget.conversationId));
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppAvatar(
              fallbackText: 'U',
              size: AvatarSize.sm,
            ),
            const SizedBox(width: 10),
            Text(
              '用户 ${widget.participantId?.substring(0, 8) ?? ''}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: '开始聊天吧',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final showDate = index == 0 ||
                        _isDifferentDay(
                          messages[index - 1].createdAt,
                          msg.createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate)
                          DateSeparator(date: msg.createdAt),
                        MessageBubble(
                          content: msg.content,
                          isMe: true, // Simplified - should check against current user
                          status: msg.status,
                          createdAt: msg.createdAt,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const LoadingState(),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(
                  messagesProvider(widget.conversationId),
                ),
              ),
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: AppStrings.typeMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9999),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}
