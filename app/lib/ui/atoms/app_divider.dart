import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 极细分隔线。默认 0.5px Twitter hairline。
class AppDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final double height;

  const AppDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.height = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: 0.5,
      indent: indent,
      endIndent: endIndent,
      color: Theme.of(context).appBorder,
    );
  }
}
