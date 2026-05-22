import 'package:flutter/material.dart';

import 'app_haptic.dart';

/// 统一的可点击容器。
///
/// 涟漪/高亮色基于 [Theme.of].colorScheme.onSurface，自适应深浅色。
/// 可选 [haptic] 在按下时触发轻触反馈。
class AppTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool haptic;
  final Color? overlayColor;

  const AppTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.padding,
    this.haptic = true,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = overlayColor ?? Theme.of(context).colorScheme.onSurface;
    final br = borderRadius ?? BorderRadius.zero;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                if (haptic) AppHaptic.light();
                onTap!();
              },
        onLongPress: onLongPress == null
            ? null
            : () {
                if (haptic) AppHaptic.medium();
                onLongPress!();
              },
        borderRadius: br,
        splashColor: base.withAlpha(15),
        highlightColor: base.withAlpha(10),
        hoverColor: base.withAlpha(8),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
