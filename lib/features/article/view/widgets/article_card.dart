/// 文章卡片组件。
///
/// 「滑动卡片式」布局中的单张卡片，展示一篇文章：
/// - 顶部：序号 + 标题 + 难度徽标；
/// - 主体：Markdown 渲染的正文（内部可独立滚动，避免内容溢出）。
library;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/markdown_view.dart';
import '../../models/article.dart';

/// 单篇文章卡片。
class ArticleCard extends StatelessWidget {
  final Article article;

  /// 卡片在列表中的位置（从 1 开始，用于序号展示）。
  final int index;

  const ArticleCard({
    super.key,
    required this.article,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // -----------------------------------------------------------------
          // 卡片头部：序号 + 标题 + 难度徽标
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // 序号徽章
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B6CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$index',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B6CF6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 难度徽标
                    _LevelBadge(level: article.level),
                  ],
                ),
                const SizedBox(height: 10),
                // 标题
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),

          // -----------------------------------------------------------------
          // 卡片主体：文章正文（内部可滚动）
          // -----------------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: MarkdownView(markdown: article.content),
            ),
          ),
        ],
      ),
    );
  }
}

/// 难度徽标（根据 level 值显示不同颜色与文案）。
class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    // 难度文案映射；level 语义由后端定义，这里提供可视化分级。
    const Map<int, String> labels = <int, String>{1: '入门', 2: '初级', 3: '中级'};
    // 颜色随难度递增由浅到深。
    const List<Color> colors = <Color>[
      Color(0xFF00A87E),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];

    final Color color = colors[(level - 1).clamp(0, colors.length - 1)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labels[level] ?? '难度 $level',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
