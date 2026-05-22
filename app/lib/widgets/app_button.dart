import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets padding;
  final double? height;
  final IconData? icon;

  const AppButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    this.height,
    this.icon,
  }) : assert(label != null || child != null, 'label or child must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buttonChild = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    variant == AppButtonVariant.primary ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
              )
            else
              Text(
                label!,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
          ],
        );

    final style = _buildStyle(theme, isDark);

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: buttonChild,
        );
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: buttonChild,
        );
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: buttonChild,
        );
        break;
    }

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }
    if (height != null) {
      button = SizedBox(height: height, child: button);
    }

    return button;
  }

  ButtonStyle _buildStyle(ThemeData theme, bool isDark) {
    final borderRadius = BorderRadius.circular(9999);

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          minimumSize: const Size(0, 48),
        );
      case AppButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          minimumSize: const Size(0, 48),
        );
      case AppButtonVariant.secondary:
        return OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: isDark ? const Color(0xFF333333) : const Color(0xFFE4E4E7)),
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          minimumSize: const Size(0, 48),
        );
      case AppButtonVariant.ghost:
        return TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          minimumSize: const Size(0, 48),
        );
    }
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final double? iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize ?? 22),
      color: color ?? theme.colorScheme.onSurface.withAlpha(180),
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
