import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AvatarSize {
  xs(14), // 28px (tile compact)
  sm(16), // 32px
  md(20), // 40px (timeline default)
  lg(28), // 56px
  xl(40); // 80px (profile)

  final double radius;
  const AvatarSize(this.radius);
}

/// 圆形头像。
///
/// - [imageUrl] 优先；空时 fallback 用 [fallbackText] 首两字符 + 主题色背景
/// - [heroTag] 提供时包裹 Hero，便于跨页面动画
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final AvatarSize size;
  final VoidCallback? onTap;
  final Object? heroTag;
  final Color? ringColor;
  final double ringWidth;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.size = AvatarSize.md,
    this.onTap,
    this.heroTag,
    this.ringColor,
    this.ringWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diameter = size.radius * 2;
    final bg = theme.appSurfaceElevated;
    final fg = theme.appTextSecondary;

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: bg),
        errorWidget: (_, __, ___) => _buildFallback(diameter, bg, fg),
      );
    } else {
      avatar = _buildFallback(diameter, bg, fg);
    }

    avatar = ClipOval(child: avatar);

    if (ringWidth > 0) {
      avatar = Container(
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          color: ringColor ?? theme.scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: avatar,
      );
    }

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallback(double diameter, Color bg, Color fg) {
    final initials = (fallbackText ?? '?').trim().isEmpty
        ? '?'
        : (fallbackText ?? '?').trim();
    final shown = initials.length > 2 ? initials.substring(0, 2) : initials;
    return Container(
      width: diameter,
      height: diameter,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        shown.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: diameter * 0.4,
          height: 1,
        ),
      ),
    );
  }
}
