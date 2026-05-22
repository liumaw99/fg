import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_duration.dart';
import '../../core/theme/app_radius.dart';

/// 骨架占位原子。基础块，靠 shimmer 透明度动画提示加载中。
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.sm,
    this.shape = BoxShape.rectangle,
  });

  /// 圆形骨架（用于头像占位）
  const AppSkeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 0,
      shape = BoxShape.circle;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).appSurfaceElevated;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, base.withAlpha(180), t),
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.radius)
                : null,
          ),
        );
      },
    );
  }
}

/// 一行文字骨架便捷构造。
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonLine({super.key, required this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(width: width, height: height);
  }
}

// 在状态切换时使用的统一过渡时长
const Duration kSkeletonFadeDuration = AppDuration.slow;
