import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 小红点/数字角标。常用于通知、消息未读数。
class AppBadge extends StatelessWidget {
  final int count;
  final double size;
  final Widget child;
  final bool dot;

  const AppBadge({
    super.key,
    required this.count,
    this.size = 18,
    required this.child,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    final theme = Theme.of(context);

    if (dot) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    final display = count > 99 ? '99+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            height: size,
            constraints: BoxConstraints(minWidth: size),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              display,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
