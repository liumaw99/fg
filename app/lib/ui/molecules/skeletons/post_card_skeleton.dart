import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../atoms/app_skeleton.dart';

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.appBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton.circle(size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLine(width: 120),
                SizedBox(height: 6),
                SkeletonLine(width: 80, height: 10),
                SizedBox(height: 14),
                SkeletonLine(width: double.infinity, height: 12),
                SizedBox(height: 6),
                SkeletonLine(width: 220, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
