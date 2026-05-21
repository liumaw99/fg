import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/post_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _maxLength = 2000;

  @override
  void dispose() {
    _contentController.dispose();
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
        // Refresh feed
        ref.read(feedPostsProvider.notifier).refresh();
        context.pop();
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createPostProvider);
    final currentLength = _contentController.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: createState.isLoading || currentLength == 0
                ? null
                : _submitPost,
            child: createState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                maxLength: _maxLength,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "What's happening?",
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Image picker
                  },
                  icon: const Icon(Icons.image_outlined),
                ),
                const Spacer(),
                Text(
                  '$currentLength / $_maxLength',
                  style: TextStyle(
                    color: currentLength > _maxLength
                        ? Colors.red
                        : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
