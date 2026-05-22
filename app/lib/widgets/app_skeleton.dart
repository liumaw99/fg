import 'package:flutter/material.dart';

class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  const AppSkeleton.circle({
    super.key,
    required double diameter,
  })  : width = diameter,
        height = diameter,
        borderRadius = 9999;

  const AppSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 4,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.08, end: 0.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: isDark
                ? Colors.white.withAlpha((_animation.value * 255).round())
                : Colors.black.withAlpha((_animation.value * 255).round()),
          ),
        );
      },
    );
  }
}

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton.circle(diameter: 40),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton.text(width: 100, height: 14),
                  SizedBox(height: 6),
                  AppSkeleton.text(width: 60, height: 12),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          AppSkeleton.text(height: 14),
          SizedBox(height: 8),
          AppSkeleton.text(width: 200, height: 14),
          SizedBox(height: 12),
          Row(
            children: [
              AppSkeleton.text(width: 40, height: 12),
              SizedBox(width: 24),
              AppSkeleton.text(width: 40, height: 12),
              SizedBox(width: 24),
              AppSkeleton.text(width: 40, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
