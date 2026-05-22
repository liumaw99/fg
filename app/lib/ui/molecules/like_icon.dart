import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_duration.dart';
import '../../core/utils/formatters.dart';
import '../atoms/app_haptic.dart';

/// 受控的点赞图标：父传 [isLiked] + [count]，本组件只负责动画 + 触觉。
///
/// - 切换为 like 时：缩放弹跳 + 心形粒子爆炸 + 轻触反馈
/// - 切换为 unlike 时：缩小回正
class LikeIcon extends StatefulWidget {
  final bool isLiked;
  final int count;
  final VoidCallback? onTap;

  const LikeIcon({
    super.key,
    required this.isLiked,
    required this.count,
    this.onTap,
  });

  @override
  State<LikeIcon> createState() => _LikeIconState();
}

class _LikeIconState extends State<LikeIcon> with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _burstCtrl;
  late Animation<double> _scale;

  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.25), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant LikeIcon old) {
    super.didUpdateWidget(old);
    if (widget.isLiked && !old.isLiked) {
      _scaleCtrl.forward(from: 0);
      _burstCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  void _handle() {
    if (widget.onTap == null) return;
    AppHaptic.light();
    if (!widget.isLiked) {
      _scaleCtrl.forward(from: 0);
      _burstCtrl.forward(from: 0);
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isLiked ? AppColors.like : theme.appTextSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: AppDuration.fast,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hover ? AppColors.like.withAlpha(20) : Colors.transparent,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _burstCtrl,
                    builder: (context, _) => CustomPaint(
                      size: const Size(40, 40),
                      painter: _BurstPainter(progress: _burstCtrl.value),
                    ),
                  ),
                  ScaleTransition(
                    scale: _scale,
                    child: Icon(
                      widget.isLiked ? Icons.favorite : Icons.favorite_outline,
                      size: 18,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.count > 0) ...[
              const SizedBox(width: 2),
              Text(
                Formatters.formatCount(widget.count),
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double progress;

  _BurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.55;
    final radius = maxRadius * progress;
    final opacity = (1 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = AppColors.like.withAlpha((opacity * 200).round())
      ..style = PaintingStyle.fill;

    // 8 个粒子环绕
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      final dotSize = 3 * (1 - progress);
      canvas.drawCircle(Offset(dx, dy), dotSize, paint);
    }

    // 中心光环
    final ringPaint = Paint()
      ..color = AppColors.like.withAlpha((opacity * 100).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * (1 - progress);
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
