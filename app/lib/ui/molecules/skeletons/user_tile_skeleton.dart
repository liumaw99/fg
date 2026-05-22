import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../atoms/app_skeleton.dart';

class UserTileSkeleton extends StatelessWidget {
  const UserTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: const [
          AppSkeleton.circle(size: 40),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 120),
                SizedBox(height: 6),
                SkeletonLine(width: 180, height: 10),
              ],
            ),
          ),
          AppSkeleton(width: 72, height: 32, radius: 9999),
        ],
      ),
    );
  }
}
