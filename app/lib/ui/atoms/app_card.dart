import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import 'app_tap.dart';

/// 卡片容器原子。无阴影，靠边框/分隔区分层级。
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool bordered;
  final Color? color;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.bordered = true,
    this.color,
    this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = color ?? theme.appSurface;

    final content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: bordered
            ? Border.all(color: theme.appBorder, width: 0.5)
            : null,
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return content;
    return AppTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }
}
