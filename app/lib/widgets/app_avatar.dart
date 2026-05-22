import 'package:flutter/material.dart';

enum AvatarSize { xs, sm, md, lg, xl }

class AppAvatar extends StatelessWidget {
  final String? url;
  final String? fallbackText;
  final AvatarSize size;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.url,
    this.fallbackText,
    this.size = AvatarSize.md,
    this.onTap,
  });

  double get _radius {
    switch (size) {
      case AvatarSize.xs:
        return 14;
      case AvatarSize.sm:
        return 18;
      case AvatarSize.md:
        return 24;
      case AvatarSize.lg:
        return 36;
      case AvatarSize.xl:
        return 48;
    }
  }

  double get _fontSize {
    switch (size) {
      case AvatarSize.xs:
        return 10;
      case AvatarSize.sm:
        return 12;
      case AvatarSize.md:
        return 14;
      case AvatarSize.lg:
        return 20;
      case AvatarSize.xl:
        return 24;
    }
  }

  String get _initials {
    final text = fallbackText ?? '';
    if (text.isEmpty) return '';
    return text.substring(0, text.length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diameter = _radius * 2;

    Widget avatar = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withAlpha(25),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.transparent,
          width: 0.5,
        ),
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(theme),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: _radius * 0.6,
                      height: _radius * 0.6,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              )
            : _fallback(theme),
      ),
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _fallback(ThemeData theme) {
    return Center(
      child: _initials.isNotEmpty
          ? Text(
              _initials,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(
              Icons.person,
              size: _radius * 0.8,
              color: theme.colorScheme.primary.withAlpha(150),
            ),
    );
  }
}
