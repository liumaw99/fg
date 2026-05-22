import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/formatters.dart';

enum BubbleStatus { sending, sent, failed }

/// 消息气泡（纯展示，无业务依赖）。
class MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final BubbleStatus status;
  final DateTime createdAt;

  const MessageBubble({
    super.key,
    required this.content,
    required this.isMe,
    required this.status,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isMe ? theme.appAccent : theme.appSurfaceElevated;
    final fg = isMe ? theme.appAccentText : theme.appTextPrimary;
    final metaFg = isMe
        ? theme.appAccentText.withAlpha(160)
        : theme.appTextSecondary;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMe ? AppRadius.lg : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: fg,
                letterSpacing: -0.05,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.formatChatTime(createdAt),
                  style: TextStyle(fontSize: 10, color: metaFg, height: 1),
                ),
                if (isMe) ...[const SizedBox(width: 4), _statusIcon(metaFg)],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(Color color) {
    switch (status) {
      case BubbleStatus.sending:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case BubbleStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 12,
          color: AppColors.danger,
        );
      case BubbleStatus.sent:
        return Icon(Icons.done, size: 12, color: color);
    }
  }
}

/// 聊天日期分隔。
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.appBorder;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(date),
              style: TextStyle(fontSize: 12, color: theme.appTextSecondary),
            ),
          ),
          Expanded(child: Divider(color: color, thickness: 0.5)),
        ],
      ),
    );
  }

  String _label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '${date.month}月${date.day}日';
  }
}
