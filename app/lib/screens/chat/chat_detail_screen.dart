import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/user_provider.dart';
import '../../ui/atoms/app_avatar.dart';
import '../../ui/atoms/app_haptic.dart';
import '../../ui/molecules/message_bubble.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';
import '../../ui/states/loading_state.dart';

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
  bool _composeActive = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final active = _controller.text.trim().isNotEmpty;
      if (active != _composeActive) {
        setState(() => _composeActive = active);
      }
    });
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
    AppHaptic.light();

    final clientMsgId =
        'client-${DateTime.now().millisecondsSinceEpoch}-${_msgCounter++}';
    _controller.clear();
    FocusScope.of(context).unfocus();

    await ref
        .read(sendMessageProvider.notifier)
        .send(
          conversationId: widget.conversationId,
          content: content,
          clientMessageId: clientMsgId,
        );

    if (mounted) {
      ref.invalidate(messagesProvider(widget.conversationId));
      _scrollToBottom();
    }
  }

  BubbleStatus _mapStatus(String status) {
    switch (status) {
      case 'sending':
        return BubbleStatus.sending;
      case 'failed':
        return BubbleStatus.failed;
      default:
        return BubbleStatus.sent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final me = ref.watch(currentUserProvider).valueOrNull;
    final currentUserId = me?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const AppAvatar(fallbackText: 'U', size: AvatarSize.sm),
            const SizedBox(width: 10),
            Text(
              '用户 ${widget.participantId?.substring(0, 6) ?? ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.appTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const EmptyState(
                      key: ValueKey('chat-empty'),
                      icon: Icons.chat_bubble_outline,
                      title: '开始聊天吧',
                      subtitle: '发送第一条消息开启对话',
                    );
                  }

                  return ListView.builder(
                    key: const ValueKey('chat-list'),
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final showDate =
                          index == 0 ||
                          _isDifferentDay(
                            messages[index - 1].createdAt,
                            msg.createdAt,
                          );
                      final isMe = msg.senderId == currentUserId;

                      return Column(
                        children: [
                          if (showDate) DateSeparator(date: msg.createdAt),
                          MessageBubble(
                            content: msg.content,
                            isMe: isMe,
                            status: _mapStatus(msg.status),
                            createdAt: msg.createdAt,
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () =>
                    const LoadingState(key: ValueKey('chat-loading')),
                error: (error, _) => ErrorState(
                  key: const ValueKey('chat-error'),
                  message: error.toString(),
                  onRetry: () =>
                      ref.invalidate(messagesProvider(widget.conversationId)),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.appBorder, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.appTextPrimary,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.typeMessage,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.appSurfaceElevated,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _composeActive
                            ? theme.appAccent
                            : theme.appSurfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _composeActive ? _sendMessage : null,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: _composeActive
                                ? theme.appAccentText
                                : theme.appTextSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
