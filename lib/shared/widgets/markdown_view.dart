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
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import 'fullscreen_image_viewer.dart';

/// Markdown 内容渲染组件。
class MarkdownView extends StatelessWidget {
  /// 待渲染的 Markdown 文本。
  final String markdown;

  /// 是否使用 Wiki 稿件中的深色代码卡片。
  final bool darkCodeBlocks;
  const MarkdownView({
    super.key,
    required this.markdown,
    this.darkCodeBlocks = false,
  });

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

    final List<({String content, bool isCode, String language})> segments =
        _splitMarkdown(markdown);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ({String content, bool isCode, String language}) segment
            in segments)
          if (segment.isCode)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _CopyableCodeBlock(
                code: segment.content,
                language: segment.language,
                dark: darkCodeBlocks,
              ),
            )
          else if (segment.content.trim().isNotEmpty)
            _buildMarkdownBody(context, segment.content, styleSheet),
      ],
    );
  }

  Widget _buildMarkdownBody(
    BuildContext context,
    String source,
    MarkdownStyleSheet styleSheet,
  ) {
    return MarkdownBody(
      data: source,
      selectable: true,
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
        final double imageWidth = (MediaQuery.sizeOf(context).width - 64).clamp(
          120.0,
          720.0,
        );
        final String imageUrl = uri.hasScheme
            ? uri.toString()
            : Uri.parse(AppConstants.kbApiBaseUrl).resolveUri(uri).toString();
        return Semantics(
          button: true,
          label: '${config.alt ?? 'Wiki 图片'}，点击全屏查看',
          child: Tooltip(
            message: '点击全屏查看',
            child: InkWell(
              key: ValueKey<String>('markdown-image-$imageUrl'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FullscreenImageViewer(
                    imageUrl: imageUrl,
                    semanticLabel: config.alt ?? 'Wiki 图片',
                  ),
                ),
              ),
              child: SizedBox(
                width: imageWidth,
                height: 160,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, _, _) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<({String content, bool isCode, String language})> _splitMarkdown(
    String source,
  ) {
    final RegExp fencedCode = RegExp(
      r'```([^\r\n]*)\r?\n([\s\S]*?)(?:\r?\n)?```',
    );
    final List<({String content, bool isCode, String language})> segments =
        <({String content, bool isCode, String language})>[];
    int cursor = 0;
    for (final RegExpMatch match in fencedCode.allMatches(source)) {
      if (match.start > cursor) {
        segments.add((
          content: source.substring(cursor, match.start),
          isCode: false,
          language: '',
        ));
      }
      segments.add((
        content: match.group(2) ?? '',
        isCode: true,
        language: match.group(1)?.trim() ?? '',
      ));
      cursor = match.end;
    }
    if (cursor < source.length) {
      segments.add((
        content: source.substring(cursor),
        isCode: false,
        language: '',
      ));
    }
    if (segments.isEmpty) {
      segments.add((content: source, isCode: false, language: ''));
    }
    return segments;
  }
}

/// 为围栏代码块增加长按复制交互。
class _CopyableCodeBlock extends StatelessWidget {
  final String code;

  final String language;
  final bool dark;
  const _CopyableCodeBlock({
    required this.code,
    required this.language,
    required this.dark,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('代码已复制'), duration: Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '代码块，长按复制',
      child: GestureDetector(
        key: const ValueKey<String>('markdown-code-block'),
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _copy(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF161616) : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      language.isEmpty ? 'CODE' : language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: dark
                            ? const Color(0xFFC6C6C6)
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.content_copy, size: 14),
                    label: const Text('复制'),
                    style: TextButton.styleFrom(
                      foregroundColor: dark
                          ? const Color(0xFFF4F4F4)
                          : colors.primary,
                    ),
                  ),
                ],
              ),
              Text(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: dark
                      ? const Color(0xFFF4F4F4)
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 后期扩展：可在现有语言标签基础上增加语法高亮。
