/// 主题（明暗模式）控制器。
///
/// 负责：
/// - 读取 / 写入当前主题模式（明亮 / 黑暗）；
/// - 使用 `shared_preferences` 持久化用户选择，重启后仍保留。
///
/// 使用 `AsyncNotifier` 是因为首次需要异步读取本地存储；
/// 在读取完成前，UI 可用 `.value ?? ThemeMode.light` 兜底为明亮模式。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题控制器。
class ThemeController extends AsyncNotifier<ThemeMode> {
  /// 本地存储中的主题模式键。
  static const String prefsKey = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    // 读取持久化的主题模式；无记录或未知值则默认明亮模式。
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(prefsKey);
    return saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  /// 设置是否使用深色模式（true = 深色，false = 明亮）。
  ///
  /// 同步更新内存状态并持久化，UI 会自动响应。
  Future<void> setDarkMode({required bool dark}) async {
    final ThemeMode mode = dark ? ThemeMode.dark : ThemeMode.light;
    // 立即更新内存状态（触发界面重建），随后异步持久化。
    state = AsyncData<ThemeMode>(mode);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, dark ? 'dark' : 'light');
  }
}

/// 主题控制器 Provider。
///
/// Riverpod 3 中所有 Provider 默认 autoDispose；主题模式被全局引用，
/// 通常不会被释放。若后续出现重建问题，可显式调用 `.keepAlive()` 保持常驻。
final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
