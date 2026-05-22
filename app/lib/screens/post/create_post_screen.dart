import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
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
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  final List<_SelectedImage> _images = [];
  static const _maxLength = 2000;
  static const _maxImages = 4;
  bool _uploadingMedia = false;

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      _showSnack('最多添加 $_maxImages 张图片');
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 88,
        limit: remaining,
      );
      if (picked.isEmpty) return;

      final next = <_SelectedImage>[];
      for (final file in picked.take(remaining)) {
        final bytes = await file.readAsBytes();
        next.add(_SelectedImage(file: file, bytes: bytes));
      }
      if (!mounted) return;
      setState(() => _images.addAll(next));
    } catch (error) {
      if (mounted) _showSnack('选择图片失败: $error');
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_images.isEmpty) return const [];

    final api = ref.read(postApiProvider);
    final ids = <String>[];
    setState(() => _uploadingMedia = true);
    try {
      for (final image in _images) {
        final mediaAssetId = await api.uploadPostImage(
          filename: image.file.name,
          mimeType: image.mimeType,
          bytes: image.bytes,
        );
        ids.add(mediaAssetId);
      }
      return ids;
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    try {
      final mediaAssetIds = await _uploadImages();
      final notifier = ref.read(createPostProvider.notifier);
      await notifier.createPost(content, mediaAssetIds: mediaAssetIds);
    } catch (error) {
      if (mounted) _showSnack('发布失败: $error');
      return;
    }

    if (!mounted) return;

    final state = ref.read(createPostProvider);
    state.whenOrNull(
      data: (_) {
        ref.read(feedPostsProvider.notifier).refresh();
        context.pop();
      },
      error: (error, _) => _showSnack('发布失败: $error'),
    );
  }

  void _applyPrompt(String text) {
    if (_contentController.text.trim().isEmpty) {
      _contentController.text = text;
    } else {
      _contentController.text = '${_contentController.text.trim()}\n$text';
    }
    _contentController.selection = TextSelection.collapsed(
      offset: _contentController.text.length,
    );
    setState(() {});
    _focusNode.requestFocus();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createState = ref.watch(createPostProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;
    final currentLength = _contentController.text.length;
    final progress = (currentLength / _maxLength).clamp(0.0, 1.0);
    final overLimit = currentLength > _maxLength;
    final isBusy = createState.isLoading || _uploadingMedia;
    final canPost = !isBusy && currentLength > 0 && !overLimit;

    return Scaffold(
      backgroundColor: theme.appBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isBusy ? null : () => context.pop(),
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
              label: _uploadingMedia ? '上传中' : AppStrings.post,
              onPressed: canPost ? _submitPost : null,
              loading: isBusy,
              size: AppButtonSize.compact,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ComposerCard(
                          avatarUrl: me?.avatarUrl,
                          identity: me?.displayNameOrUsername ?? 'Me',
                          username: me?.username,
                          controller: _contentController,
                          focusNode: _focusNode,
                          maxLength: _maxLength,
                          onChanged: () => setState(() {}),
                        ),
                        if (_images.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ImagePreviewGrid(
                            images: _images,
                            onRemove: isBusy
                                ? null
                                : (index) {
                                    setState(() => _images.removeAt(index));
                                  },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _PromptRail(onTap: _applyPrompt),
                      ],
                    ),
                  ),
                ),
                _ComposerToolbar(
                  progress: progress,
                  overLimit: overLimit,
                  remaining: _maxLength - currentLength,
                  imageCount: _images.length,
                  maxImages: _maxImages,
                  onPickImages: isBusy ? null : _pickImages,
                  onUnavailable: () => _showSnack('功能即将上线'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedImage {
  final XFile file;
  final Uint8List bytes;

  const _SelectedImage({required this.file, required this.bytes});

  String get mimeType {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

class _ComposerCard extends StatelessWidget {
  final String? avatarUrl;
  final String identity;
  final String? username;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final VoidCallback onChanged;

  const _ComposerCard({
    required this.avatarUrl,
    required this.identity,
    required this.username,
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.appSurface.withAlpha(theme.isDark ? 130 : 220),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.appBorder, width: 0.7),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: avatarUrl,
                fallbackText: identity,
                size: AvatarSize.md,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.appTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username == null ? '公开发布' : '以 @$username 发布',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.appTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            minLines: 8,
            maxLength: maxLength,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            style: TextStyle(
              fontSize: 22,
              height: 1.45,
              color: theme.appTextPrimary,
              letterSpacing: -0.25,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '把正在发生的事写下来。',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              counterText: '',
              contentPadding: EdgeInsets.zero,
              hintStyle: TextStyle(
                fontSize: 22,
                height: 1.45,
                color: theme.appTextTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewGrid extends StatelessWidget {
  final List<_SelectedImage> images;
  final ValueChanged<int>? onRemove;

  const _ImagePreviewGrid({required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(color: theme.appSurface, child: _layout()),
      ),
    );
  }

  Widget _layout() {
    if (images.length == 1) return _tile(0);
    if (images.length == 2) {
      return Row(
        children: [
          Expanded(child: _tile(0)),
          _gapX,
          Expanded(child: _tile(1)),
        ],
      );
    }
    if (images.length == 3) {
      return Row(
        children: [
          Expanded(child: _tile(0)),
          _gapX,
          Expanded(
            child: Column(
              children: [
                Expanded(child: _tile(1)),
                _gapY,
                Expanded(child: _tile(2)),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(0)),
              _gapX,
              Expanded(child: _tile(1)),
            ],
          ),
        ),
        _gapY,
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(2)),
              _gapX,
              Expanded(child: _tile(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget get _gapX => const SizedBox(width: 2);
  Widget get _gapY => const SizedBox(height: 2);

  Widget _tile(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(images[index].bytes, fit: BoxFit.cover),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black.withAlpha(170),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove == null ? null : () => onRemove!(index),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.close, size: 17, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptRail extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _PromptRail({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final prompts = const ['今天的一个小进展：', '我想问大家一个问题：', '刚刚想到一个点子：'];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final prompt in prompts)
          _PromptChip(
            label: prompt.replaceAll('：', ''),
            onTap: () => onTap(prompt),
          ),
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: theme.appBorderStrong)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: theme.appTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerToolbar extends StatelessWidget {
  final double progress;
  final bool overLimit;
  final int remaining;
  final int imageCount;
  final int maxImages;
  final VoidCallback? onPickImages;
  final VoidCallback onUnavailable;

  const _ComposerToolbar({
    required this.progress,
    required this.overLimit,
    required this.remaining,
    required this.imageCount,
    required this.maxImages,
    required this.onPickImages,
    required this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.appBackground,
        border: Border(top: BorderSide(color: theme.appBorder, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.image_outlined,
              label: '$imageCount/$maxImages',
              onTap: onPickImages,
            ),
            _ToolButton(icon: Icons.gif_box_outlined, onTap: onUnavailable),
            _ToolButton(icon: Icons.tag_rounded, onTap: onUnavailable),
            const Spacer(),
            if (imageCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Text(
                  '$imageCount 张图片',
                  style: TextStyle(
                    color: theme.appTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _CounterRing(
              progress: progress,
              overLimit: overLimit,
              remaining: remaining,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  const _ToolButton({required this.icon, this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: theme.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: theme.appTextPrimary),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: TextStyle(
                      color: theme.appTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2.5,
            backgroundColor: theme.appBorder,
            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
          ),
        ),
      ],
    );
  }
}
