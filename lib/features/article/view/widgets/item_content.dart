/// 单个条目的完整内容组件（阅读视图核心）。
///
/// 对应需求中的页面布局：
/// ```
/// 文章标题（= 条目的 question）
/// 作者:xxx，最后更新：yyyy-MM-dd
/// ┌ 01 Description ┐
/// ┌ 02 Causes      ┐
/// ┌ 03 Solutions   ┐
/// ┌ 04 Review      ┐
/// ```
///
/// 本组件为「纯展示」：接收一条 [ArticleItem] 与文章级元信息，
/// 供「滑动卡片」与「条目详情页」复用，避免两处重复渲染逻辑。
library;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/markdown_view.dart';
import '../../models/article.dart';

/// 单个条目的完整内容。
class ItemContent extends StatelessWidget {
  /// 待展示的条目。
  final ArticleItem item;

  /// 文章级「最后更新」时间（同一篇文章的所有条目共享）。
  final DateTime? updatedAt;

  const ItemContent({
    super.key,
    required this.item,
    required this.updatedAt,
  });

  /// 四章正文的标题（与后端字段一一对应）。
  static const List<String> _sectionTitles = <String>[
    'Description',
    'Causes',
    'Solutions',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    // 四章正文内容（可能为空）。
    final List<String?> sections = <String?>[
      item.description,
      item.causes,
      item.solutions,
      item.review,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ---------------------------------------------------------------------
        // 标题（条目的 question）
        // ---------------------------------------------------------------------
        Text(
          item.displayTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),

        // ---------------------------------------------------------------------
        // 元信息：作者（占位） + 最后更新
        // ---------------------------------------------------------------------
        Row(
          children: <Widget>[
            const Icon(Icons.person_outline_rounded,
                size: 15, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            // 作者信息后端暂未返回，先以「待定」占位，后期接口补充后再替换。
            const Text(
              '作者：待定',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.schedule_rounded,
                size: 15, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(
              '最后更新：${_formatDate(updatedAt)}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // 四章正文卡片
        // ---------------------------------------------------------------------
        for (int i = 0; i < sections.length; i++)
          _SectionCard(
            number: i + 1,
            title: _sectionTitles[i],
            markdown: sections[i],
          ),
      ],
    );
  }

  /// 将时间格式化为 `yyyy-MM-dd`；为 null 时返回占位符。
  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// 单个章节卡片（如「01 Description」）。
class _SectionCard extends StatelessWidget {
  /// 章节序号（从 1 开始）。
  final int number;

  /// 章节标题。
  final String title;

  /// 章节正文（Markdown，可能为空）。
  final String? markdown;

  const _SectionCard({
    required this.number,
    required this.title,
    required this.markdown,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasContent = markdown != null && markdown!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 章节标题行：序号 + 标题
          Row(
            children: <Widget>[
              Text(
                number.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3B6CF6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F1F3)),
          const SizedBox(height: 12),
          // 正文：有内容渲染 Markdown，无内容展示占位。
          if (hasContent)
            MarkdownView(markdown: markdown!)
          else
            const Text(
              '暂无内容',
              style: TextStyle(fontSize: 13, color: Color(0xFFB0B5BD)),
            ),
        ],
      ),
    );
  }
}
