import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import 'app_haptic.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { compact, regular, large }

/// 应用全局按钮原子。Twitter 风格 pill 形态。
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onPressed == null || loading;

    final colors = _resolveColors(theme);

    final height = switch (size) {
      AppButtonSize.compact => 32.0,
      AppButtonSize.regular => 40.0,
      AppButtonSize.large => 48.0,
    };
    final hPad = switch (size) {
      AppButtonSize.compact => 16.0,
      AppButtonSize.regular => 22.0,
      AppButtonSize.large => 28.0,
    };
    final fontSize = switch (size) {
      AppButtonSize.compact => 13.0,
      AppButtonSize.regular => 15.0,
      AppButtonSize.large => 16.0,
    };

    final button = Material(
      color: colors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: colors.border == null
            ? BorderSide.none
            : BorderSide(color: colors.border!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: disabled
            ? null
            : () {
                AppHaptic.light();
                onPressed!();
              },
        splashColor: colors.fg.withAlpha(20),
        highlightColor: colors.fg.withAlpha(10),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: fontSize,
                  height: fontSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.fg),
                  ),
                )
              else if (icon != null)
                Icon(icon, size: fontSize + 2, color: colors.fg),
              if ((loading || icon != null)) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.fg.withAlpha(disabled ? 140 : 255),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  _ButtonColors _resolveColors(ThemeData theme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(
          bg: theme.appAccent,
          fg: theme.appAccentText,
          border: null,
        );
      case AppButtonVariant.secondary:
        return _ButtonColors(
          bg: Colors.transparent,
          fg: theme.appTextPrimary,
          border: theme.appBorderStrong,
        );
      case AppButtonVariant.ghost:
        return _ButtonColors(
          bg: Colors.transparent,
          fg: theme.appTextPrimary,
          border: null,
        );
      case AppButtonVariant.danger:
        return _ButtonColors(
          bg: Colors.transparent,
          fg: AppColors.danger,
          border: AppColors.danger,
        );
    }
  }
}

class _ButtonColors {
  final Color bg;
  final Color fg;
  final Color? border;

  _ButtonColors({required this.bg, required this.fg, this.border});
}
