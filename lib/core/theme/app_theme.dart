/// 应用主题配置。
///
/// 集中管理配色、文字样式、组件主题。
/// 后期如需支持「全局设置」里的明暗主题切换，可在此扩展 [ThemeData] 的生成逻辑。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'busybox_palette.dart';

/// 主题工厂类。
abstract final class AppTheme {
  /// 品牌主色（用于按钮、导航栏高亮等）。
  static const Color primaryColor = Color(0xFF3B6CF6);

  /// 生成明亮主题。
  static ThemeData get light => ThemeData(
    extensions: const <ThemeExtension<dynamic>>[BusyBoxPalette.light],
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1A1A1A),

      // 疑似能解决状态栏颜色与页面颜色不一致的问题
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF5F6FA),
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 5,
    ),
  );

  /// 生成深色主题（预留：后续「全局设置」开启深色模式时使用）。
  static ThemeData get dark => ThemeData(
    extensions: const <ThemeExtension<dynamic>>[BusyBoxPalette.dark],
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Color(0xFF121212),
        statusBarIconBrightness: Brightness.light,
      ),
    ),
  );
}
