/// 轻量级 Markdown 内容渲染组件。
///
/// 文章接口返回的 `content` 为 Markdown 文本，其中包含：
/// - `### 小节标题`
/// - `- 无序列表项` / `1. 有序列表项`
/// - `**加粗**`、`` `行内代码` ``、`[链接](url)`
/// - `---` 分隔线
///
/// 本组件解析上述常用语法并渲染为样式化的 Widget。
/// 若后期内容格式更复杂，可替换为完整的 Markdown 渲染库，
/// 只需保持对外接口（接收 String 返回 Widget）不变。
library;

import 'package:flutter/material.dart';

/// Markdown 内容渲染组件。
class MarkdownView extends StatelessWidget {
  /// 待渲染的 Markdown 文本。
  final String markdown;

  const MarkdownView({super.key, required this.markdown});

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _parseBlocks(markdown);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // ---------------------------------------------------------------------------
  // 块级解析
  // ---------------------------------------------------------------------------

  /// 将整段文本解析为 Widget 列表。
  List<Widget> _parseBlocks(String text) {
    final List<Widget> result = <Widget>[];
    // 按行拆分并去除行尾空白，保留空行用于段落间距控制。
    final List<String> lines =
        text.split('\n').map((line) => line.trimRight()).toList();

    // 已处理的空行缓存（用于将连续空行合并为一个间距）。
    bool skipBlank = false;

    for (final String rawLine in lines) {
      final String line = rawLine.trim();

      // 分隔线：`---` 或连续三个以上 `-`
      if (RegExp(r'^-{3,}$').hasMatch(line)) {
        if (result.isNotEmpty) result.add(const Divider(height: 24));
        skipBlank = true;
        continue;
      }

      // 空行：合并为单一间距
      if (line.isEmpty) {
        if (!skipBlank) {
          result.add(const SizedBox(height: 8));
          skipBlank = true;
        }
        continue;
      }
      skipBlank = false;

      // `### ` 小节标题
      if (line.startsWith('### ')) {
        result.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              line.substring(4),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        );
        continue;
      }

      // `- ` / `* ` 无序列表项
      if (line.startsWith('- ') || line.startsWith('* ')) {
        result.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 6),
                  child: Text('•', style: TextStyle(color: Color(0xFF3B6CF6))),
                ),
                Expanded(
                  child: _InlineRichText(
                    line.substring(2),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // `1. ` / `2. ` 有序列表项
      final Match? ordered = RegExp(r'^(\d+)[.、]\s*(.*)$').firstMatch(line);
      if (ordered != null) {
        result.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Text(
                    '${ordered.group(1)}.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B6CF6),
                    ),
                  ),
                ),
                Expanded(
                  child: _InlineRichText(
                    ordered.group(2)!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 普通正文
      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _InlineRichText(
            line,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF374151),
            ),
          ),
        ),
      );
    }

    return result;
  }
}

/// 行内格式（加粗、行内代码）渲染。
class _InlineRichText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _InlineRichText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: _parseInline(text, style)));
  }

  /// 解析行内语法：`**加粗**`、`` `代码` ``。
  static List<InlineSpan> _parseInline(String text, TextStyle style) {
    final List<InlineSpan> spans = <InlineSpan>[];
    // 使用正则分割：`**text**` 与 `` `code` `` 会作为整体匹配。
    final RegExp pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`)');
    int lastEnd = 0;

    for (final RegExpMatch match in pattern.allMatches(text)) {
      // 匹配前的普通文本。
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final String token = match.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
      } else {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: const Color(0xFFF3F4F6),
            color: const Color(0xFFD97706),
          ),
        ));
      }
      lastEnd = match.end;
    }
    // 尾部剩余普通文本。
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans;
  }
}
