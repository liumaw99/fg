import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_button.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _maxLength = 2000;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createPostProvider);
    final currentLength = _contentController.text.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.newPost),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppButton(
              label: AppStrings.post,
              onPressed: createState.isLoading || currentLength == 0
                  ? null
                  : _submitPost,
              isLoading: createState.isLoading,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppAvatar(
                    fallbackText: 'Me',
                    size: AvatarSize.md,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      focusNode: _focusNode,
                      maxLines: null,
                      maxLength: _maxLength,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: AppStrings.whatsHappening,
                        border: InputBorder.none,
                        counterText: '',
                        hintStyle: TextStyle(
                          fontSize: 18,
                          color: isDark
                              ? const Color(0xFF71717A)
                              : const Color(0xFFA1A1AA),
                        ),
                      ),
                      style: const TextStyle(fontSize: 17, height: 1.6),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.image_outlined),
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.gif_box_outlined),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Spacer(),
                Text(
                  '$currentLength / $_maxLength',
                  style: TextStyle(
                    fontSize: 13,
                    color: currentLength > _maxLength
                        ? Theme.of(context).colorScheme.error
                        : (isDark
                            ? const Color(0xFF71717A)
                            : const Color(0xFFA1A1AA)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
