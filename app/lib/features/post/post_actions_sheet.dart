import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';

/// 动态详情底部弹窗：复制链接 / 删除（仅自己） / 举报。
Future<void> showPostActionsSheet(BuildContext context, {required PostModel post}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).appBackground,
    builder: (ctx) => _PostActionsSheet(post: post),
  );
}

class _PostActionsSheet extends ConsumerWidget {
  final PostModel post;
  const _PostActionsSheet({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final isOwner = me?.id == post.userId;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Item(
            icon: Icons.link,
            label: '复制链接',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: 'fg://post/${post.id}'));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('链接已复制')),
                );
              }
            },
          ),
          if (isOwner)
            _Item(
              icon: Icons.delete_outline,
              label: '删除',
              danger: true,
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('确认删除？'),
                    content: const Text('删除后将无法恢复'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('删除', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  // TODO: 接入 deletePost API
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除功能即将上线')),
                  );
                  await ref.read(feedPostsProvider.notifier).refresh();
                }
              },
            ),
          if (!isOwner)
            _Item(
              icon: Icons.flag_outlined,
              label: '举报',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('举报功能即将上线')),
                );
              },
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger ? AppColors.danger : theme.appTextPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
