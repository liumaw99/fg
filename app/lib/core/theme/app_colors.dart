import 'package:flutter/material.dart';

/// Twitter × Next.js 风格的纯黑白灰配色 token
class AppColors {
  AppColors._();

  // ── Dark mode ──
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF16181C);
  static const Color darkSurfaceElevated = Color(0xFF1D1F23);
  static const Color darkBorder = Color(0xFF2F3336);
  static const Color darkBorderStrong = Color(0xFF3E4144);
  static const Color darkTextPrimary = Color(0xFFE7E9EA);
  static const Color darkTextSecondary = Color(0xFF71767B);
  static const Color darkTextTertiary = Color(0xFF536471);
  static const Color darkAccent = Color(0xFFFFFFFF);
  static const Color darkAccentText = Color(0xFF000000);

  // ── Light mode ──
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F9F9);
  static const Color lightSurfaceElevated = Color(0xFFEFF3F4);
  static const Color lightBorder = Color(0xFFEFF3F4);
  static const Color lightBorderStrong = Color(0xFFCFD9DE);
  static const Color lightTextPrimary = Color(0xFF0F1419);
  static const Color lightTextSecondary = Color(0xFF536471);
  static const Color lightTextTertiary = Color(0xFF828A93);
  static const Color lightAccent = Color(0xFF0F1419);
  static const Color lightAccentText = Color(0xFFFFFFFF);

  // ── Semantic (跨模式共用) ──
  static const Color like = Color(0xFFF91880); // Twitter heart pink
  static const Color repost = Color(0xFF00BA7C); // Twitter retweet green
  static const Color danger = Color(0xFFF4212E); // Twitter delete red
}

/// 当前主题下的语义化颜色提取
extension AppColorsX on ThemeData {
  bool get isDark => brightness == Brightness.dark;

  Color get appBackground =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get appSurface =>
      isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get appSurfaceElevated =>
      isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
  Color get appBorder => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get appBorderStrong =>
      isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;
  Color get appTextPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get appTextSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get appTextTertiary =>
      isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
  Color get appAccent => isDark ? AppColors.darkAccent : AppColors.lightAccent;
  Color get appAccentText =>
      isDark ? AppColors.darkAccentText : AppColors.lightAccentText;
}
