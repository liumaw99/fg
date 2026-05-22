import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final String? message;

  const LoadingState({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
