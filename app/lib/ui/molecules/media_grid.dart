import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../atoms/app_skeleton.dart';

/// Twitter 标准 1/2/3/4 张图布局。
class MediaGrid extends StatelessWidget {
  final List<String> imageUrls;
  final void Function(int index)? onTap;
  final double radius;

  const MediaGrid({
    super.key,
    required this.imageUrls,
    this.onTap,
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: _buildLayout(context),
    );
  }

  Widget _buildLayout(BuildContext context) {
    switch (imageUrls.length) {
      case 1:
        return AspectRatio(aspectRatio: 16 / 9, child: _image(0));
      case 2:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Row(
            children: [
              Expanded(child: _image(0)),
              const SizedBox(width: 2),
              Expanded(child: _image(1)),
            ],
          ),
        );
      case 3:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Row(
            children: [
              Expanded(child: _image(0)),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _image(1)),
                    const SizedBox(height: 2),
                    Expanded(child: _image(2)),
                  ],
                ),
              ),
            ],
          ),
        );
      case 4:
      default:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _image(0)),
                    const SizedBox(width: 2),
                    Expanded(child: _image(1)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _image(2)),
                    const SizedBox(width: 2),
                    Expanded(child: _image(3)),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _image(int index) {
    final url = imageUrls[index];
    final img = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const AppSkeleton(
        width: double.infinity,
        height: double.infinity,
        radius: 0,
      ),
      errorWidget: (context, _, __) => _ErrorPlaceholder(),
      fadeInDuration: const Duration(milliseconds: 200),
    );
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(index),
      child: img,
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.appSurfaceElevated,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 32,
        color: theme.appTextSecondary,
      ),
    );
  }
}
