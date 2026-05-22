import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/storage/theme_storage.dart' as theme_storage;

part 'theme_provider.g.dart';

@riverpod
class ThemeSettings extends _$ThemeSettings {
  final theme_storage.ThemeStorage _storage = theme_storage.ThemeStorage();

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final mode = await _storage.getThemeMode();
    switch (mode) {
      case theme_storage.AppThemeMode.light:
        state = ThemeMode.light;
      case theme_storage.AppThemeMode.dark:
        state = ThemeMode.dark;
      case theme_storage.AppThemeMode.system:
        state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    theme_storage.AppThemeMode storageMode;
    switch (mode) {
      case ThemeMode.light:
        storageMode = theme_storage.AppThemeMode.light;
      case ThemeMode.dark:
        storageMode = theme_storage.AppThemeMode.dark;
      default:
        storageMode = theme_storage.AppThemeMode.system;
    }
    await _storage.setThemeMode(storageMode);
  }

  Future<void> toggle() async {
    if (state == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}
