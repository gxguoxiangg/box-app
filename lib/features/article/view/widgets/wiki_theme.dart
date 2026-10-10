/// Wiki 专用外观，复用 BusyBox 色板，不改变其余模块主题。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/busybox_palette.dart';

/// 将知识库稿件配色应用到阅读、列表和投稿页面。
/// 后期扩展：Wiki 外观统一在此维护，配色选择仍由 BusyBoxPalette 提供。
class WikiTheme extends StatelessWidget {
  /// 创建 Wiki 主题范围。
  const WikiTheme({super.key, required this.child});

  /// 使用主题的内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final p = BusyBoxPalette.of(context);
    final colors = base.colorScheme.copyWith(
      primary: p.accent,
      onPrimary: p.canvas,
      surface: p.page,
      surfaceContainerLow: p.canvas,
      surfaceContainerHighest: p.inset,
      onSurface: p.ink,
      onSurfaceVariant: p.muted,
      outlineVariant: p.border,
    );
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: base.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: base.brightness,
      systemStatusBarContrastEnforced: false,
    );
    return Theme(
      data: base.copyWith(
        colorScheme: colors,
        scaffoldBackgroundColor: p.page,
        appBarTheme: AppBarTheme(
          backgroundColor: p.canvas,
          foregroundColor: p.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: overlay,
        ),
        cardTheme: CardThemeData(
          color: p.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          margin: EdgeInsets.zero,
          shadowColor: p.ink.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.border),
          ),
        ),
        dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: p.canvas,
          selectedColor: p.accent.withValues(alpha: 0.08),
          side: BorderSide(color: p.border),
          shape: const StadiumBorder(),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: p.canvas,
          foregroundColor: p.ink,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: p.border),
          ),
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: child,
      ),
    );
  }
}

/// 列表和阅读页共用的精简标题栏。
class WikiHeader extends StatelessWidget {
  /// 创建标题栏。
  const WikiHeader({
    super.key,
    required this.onBack,
    required this.onDirectory,
    required this.backLabel,
  });

  /// 返回行为。
  final VoidCallback onBack;

  /// 打开目录。
  final VoidCallback onDirectory;

  /// 返回按钮辅助说明。
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final p = BusyBoxPalette.of(context);
    return ColoredBox(
      color: p.canvas,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: backLabel,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Wiki',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: p.ink,
                      ),
                    ),
                    Text(
                      'BusyBox · 知识库',
                      style: TextStyle(fontSize: 11, color: p.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '目录',
                onPressed: onDirectory,
                icon: const Icon(Icons.toc_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 文章元信息标签。
class WikiTag extends StatelessWidget {
  /// 创建标签。
  const WikiTag(this.text, {super.key});

  /// 显示文本。
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = BusyBoxPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: p.inset,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: p.border),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: p.muted)),
    );
  }
}
