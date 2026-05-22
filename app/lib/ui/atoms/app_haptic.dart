import 'package:flutter/services.dart';

/// 触觉反馈封装。所有按键交互统一通过此层调用，便于全局禁用/调整强度。
class AppHaptic {
  AppHaptic._();

  /// 轻触：点赞、按钮、Tab 切换
  static Future<void> light() => HapticFeedback.lightImpact();

  /// 中等：删除、确认操作
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// 选择：切换选项、滚动到顶部
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// 重击：错误、警告
  static Future<void> heavy() => HapticFeedback.heavyImpact();
}
