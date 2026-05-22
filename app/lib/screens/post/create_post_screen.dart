import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../ui/atoms/app_avatar.dart';
import '../../ui/atoms/app_button.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  static const _maxLength = 2000;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final notifier = ref.read(createPostProvider.notifier);
    await notifier.createPost(content);

    if (!mounted) return;

    final state = ref.read(createPostProvider);
    state.whenOrNull(
      data: (_) {
        ref.read(feedPostsProvider.notifier).refresh();
        context.pop();
      },
      error: (error, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发布失败: $error')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createState = ref.watch(createPostProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;
    final currentLength = _contentController.text.length;
    final progress = (currentLength / _maxLength).clamp(0.0, 1.0);
    final overLimit = currentLength > _maxLength;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text(AppStrings.newPost),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.md,
              top: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: AppButton(
              label: AppStrings.post,
              onPressed:
                  createState.isLoading || currentLength == 0 || overLimit
                  ? null
                  : _submitPost,
              loading: createState.isLoading,
              size: AppButtonSize.compact,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(
                    imageUrl: me?.avatarUrl,
                    fallbackText: me?.displayNameOrUsername ?? 'Me',
                    size: AvatarSize.md,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      focusNode: _focusNode,
                      maxLines: null,
                      maxLength: _maxLength,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: theme.appTextPrimary,
                        letterSpacing: -0.05,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.whatsHappening,
                        border: InputBorder.none,
                        counterText: '',
                        hintStyle: TextStyle(
                          fontSize: 18,
                          color: theme.appTextTertiary,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.appBorder, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.image_outlined, color: theme.appTextPrimary),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.gif_box_outlined,
                    color: theme.appTextPrimary,
                  ),
                ),
                const Spacer(),
                if (currentLength > 0)
                  _CounterRing(
                    progress: progress,
                    overLimit: overLimit,
                    remaining: _maxLength - currentLength,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterRing extends StatelessWidget {
  final double progress;
  final bool overLimit;
  final int remaining;

  const _CounterRing({
    required this.progress,
    required this.overLimit,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color ringColor;
    if (overLimit) {
      ringColor = AppColors.danger;
    } else if (progress >= 0.9) {
      ringColor = const Color(0xFFFFD400);
    } else {
      ringColor = theme.appTextPrimary;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress >= 0.8 || overLimit)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              remaining.toString(),
              style: TextStyle(
                fontSize: 13,
                color: overLimit ? AppColors.danger : theme.appTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  backgroundColor: theme.appBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
