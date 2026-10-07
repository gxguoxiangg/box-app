/// BusyBox 界面的配色模板。
///
/// 主页、抽屉与自定义页共用同一 ThemeExtension；后续增加主题选择时，
/// 只需替换 ThemeData 中的模板，无需逐页修改颜色常量。
library;

import 'package:flutter/material.dart';

/// 参考 doc/ui 三份设计稿抽出的界面色板。
@immutable
class BusyBoxPalette extends ThemeExtension<BusyBoxPalette> {
  /// 页面底色。
  final Color page;

  /// 卡片底色。
  final Color canvas;

  /// 卡片内浅色底色。
  final Color inset;

  /// 分隔线。
  final Color border;

  /// 主要文字。
  final Color ink;

  /// 次级文字。
  final Color muted;

  /// 辅助文字。
  final Color subtle;

  /// 品牌蓝。
  final Color accent;

  /// 危险操作红。
  final Color error;

  /// 状态绿。
  final Color success;

  /// 创建完整的配色模板。
  const BusyBoxPalette({
    required this.page,
    required this.canvas,
    required this.inset,
    required this.border,
    required this.ink,
    required this.muted,
    required this.subtle,
    required this.accent,
    required this.error,
    required this.success,
  });

  /// doc/ui 使用的浅色模板。
  static const BusyBoxPalette light = BusyBoxPalette(
    page: Color(0xFFF4F4F4),
    canvas: Colors.white,
    inset: Color(0xFFF4F4F4),
    border: Color(0xFFE0E0E0),
    ink: Color(0xFF161616),
    muted: Color(0xFF525252),
    subtle: Color(0xFF8C8C8C),
    accent: Color(0xFF0F62FE),
    error: Color(0xFFDA1E28),
    success: Color(0xFF24A148),
  );

  /// 与浅色模板语义一致的深色模板。
  static const BusyBoxPalette dark = BusyBoxPalette(
    page: Color(0xFF161616),
    canvas: Color(0xFF262626),
    inset: Color(0xFF393939),
    border: Color(0xFF525252),
    ink: Color(0xFFF4F4F4),
    muted: Color(0xFFC6C6C6),
    subtle: Color(0xFFA8A8A8),
    accent: Color(0xFF78A9FF),
    error: Color(0xFFFF8389),
    success: Color(0xFF42BE65),
  );

  /// 读取当前主题的配色；独立组件测试未注册扩展时按亮度兜底。
  static BusyBoxPalette of(BuildContext context) =>
      Theme.of(context).extension<BusyBoxPalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  BusyBoxPalette copyWith({
    Color? page,
    Color? canvas,
    Color? inset,
    Color? border,
    Color? ink,
    Color? muted,
    Color? subtle,
    Color? accent,
    Color? error,
    Color? success,
  }) => BusyBoxPalette(
    page: page ?? this.page,
    canvas: canvas ?? this.canvas,
    inset: inset ?? this.inset,
    border: border ?? this.border,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    subtle: subtle ?? this.subtle,
    accent: accent ?? this.accent,
    error: error ?? this.error,
    success: success ?? this.success,
  );

  @override
  BusyBoxPalette lerp(ThemeExtension<BusyBoxPalette>? other, double t) {
    if (other is! BusyBoxPalette) return this;
    return BusyBoxPalette(
      page: Color.lerp(page, other.page, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      inset: Color.lerp(inset, other.inset, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
