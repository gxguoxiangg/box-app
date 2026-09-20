/// Markdown 内容渲染组件。
///
/// 基于 Flutter 官方 [flutter_markdown] 包，正确解析常见 Markdown 语法：
/// - 标题、段落、加粗/斜体、行内代码、链接
/// - 有序 / 无序列表、引用块、分隔线
/// - **围栏代码块**（```powershell 等，含语言标签）
/// - **表格**（GFM）
/// - 图片（远程 URL）
///
/// 对外接口保持「接收 Markdown 字符串、返回 Widget」，页面无需感知底层实现。
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';

/// Markdown 内容渲染组件。
class MarkdownView extends StatelessWidget {
  /// 待渲染的 Markdown 文本。
  final String markdown;

  const MarkdownView({super.key, required this.markdown});

  @override
  Widget build(BuildContext context) {
    // 以主题为基底定制样式：统一正文排版，重点美化代码块。
    final ColorScheme colors = Theme.of(context).colorScheme;
    final MarkdownStyleSheet styleSheet =
        MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: TextStyle(fontSize: 14, height: 1.6, color: colors.onSurface),
          listBullet: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF3B6CF6),
          ),
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: colors.onSurfaceVariant,
            backgroundColor: colors.surfaceContainerHighest,
          ),
          codeblockDecoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.outlineVariant),
          ),
          codeblockPadding: const EdgeInsets.all(12),
        );

    return MarkdownBody(
      data: markdown,
      styleSheet: styleSheet,
      // 点击链接时用系统浏览器打开（外部链接）。
      onTapLink: (String text, String? href, String title) {
        if (href != null) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
      // 限制图片宽度，避免超宽图片在卡片内横向溢出。
      sizedImageBuilder: (config) {
        final Uri uri = config.uri;
        final String imageUrl = uri.hasScheme
            ? uri.toString()
            : '${AppConstants.kbApiBaseUrl}${uri.path}';
        return Image.network(imageUrl, fit: BoxFit.fitWidth);
      },
    );
  }
}
