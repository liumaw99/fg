import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../atoms/app_skeleton.dart';

class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSkeleton(width: 24, height: 24),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.circle(size: 32),
                SizedBox(height: 8),
                SkeletonLine(width: double.infinity, height: 12),
                SizedBox(height: 6),
                SkeletonLine(width: 180, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationTileSkeleton extends StatelessWidget {
  const ConversationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: const [
          AppSkeleton.circle(size: 56),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 120),
                SizedBox(height: 8),
                SkeletonLine(width: double.infinity, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
