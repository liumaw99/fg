import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_duration.dart';
import '../../core/utils/formatters.dart';
import '../atoms/app_haptic.dart';

/// 通用动作按钮（评论/转推/分享）。
///
/// 悬浮态背景圆形渐显，激活态使用 [activeColor]。
class ActionIcon extends StatefulWidget {
  final IconData icon;
  final int? count;
  final Color? activeColor;
  final bool active;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const ActionIcon({
    super.key,
    required this.icon,
    this.count,
    this.activeColor,
    this.active = false,
    this.onTap,
    this.semanticLabel,
  });

  @override
  State<ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<ActionIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoverColor = widget.activeColor ?? theme.appTextPrimary;
    final fgColor = widget.active ? (widget.activeColor ?? hoverColor) : theme.appTextSecondary;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap == null
              ? null
              : () {
                  AppHaptic.light();
                  widget.onTap!();
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppDuration.fast,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hover ? hoverColor.withAlpha(20) : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Icon(widget.icon, size: 18, color: fgColor),
              ),
              if (widget.count != null && widget.count! > 0) ...[
                const SizedBox(width: 2),
                Text(
                  Formatters.formatCount(widget.count!),
                  style: TextStyle(
                    fontSize: 13,
                    color: fgColor,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
