/// Wiki 阅读正文与投稿预览共用组件。
/// 后期扩展：新增章节时同步后端字段；作者缺失时不填充示例人物。
library;

import 'package:flutter/material.dart';
import '../../../../shared/widgets/markdown_view.dart';
import '../../models/article.dart';
import 'wiki_theme.dart';

/// 一条知识库条目的标题、真实元信息和四章内容。
class ItemContent extends StatelessWidget {
  /// 创建正文。
  const ItemContent({super.key, required this.item, required this.updatedAt});

  /// 条目内容。
  final ArticleItem item;

  /// 服务端提供的文章级更新时间，可为空。
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = updatedAt;
    final sections = <(String, String, String?)>[
      ('问题描述', 'Description', item.description),
      ('产生原因', 'Causes', item.causes),
      ('解决方案', 'Solutions', item.solutions),
      ('审查复盘', 'Review', item.review),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          item.displayTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: colors.onSurface,
          ),
        ),
        if (date != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            '最后更新：${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
        if (item.keywordList.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final keyword in item.keywordList) WikiTag('#$keyword'),
            ],
          ),
        ],
        const SizedBox(height: 16),
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 5,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            section.$1,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          section.$2,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 12),
                    if (section.$3?.trim().isNotEmpty == true)
                      MarkdownView(
                        markdown: section.$3 ?? '',
                        darkCodeBlocks: true,
                      )
                    else
                      Text(
                        '暂无内容',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
