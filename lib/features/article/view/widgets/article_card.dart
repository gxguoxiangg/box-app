/// 文章条目卡片组件（滑动卡片式布局中的单页）。
///
/// 一页 = 一个条目：标题 + 作者/更新时间 + 四章正文卡片。
/// 内容通过 [ItemContent] 渲染，内部可独立纵向滚动。
library;

import 'package:flutter/material.dart';

import '../../models/article.dart';
import 'item_content.dart';

/// 单个条目卡片。
class ArticleCard extends StatelessWidget {
  /// 待展示的条目。
  final ArticleItem item;

  /// 文章级「最后更新」时间（由浏览页从整篇文章中透传）。
  final DateTime? updatedAt;

  const ArticleCard({super.key, required this.item, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // 底部留白，避免最后的章节卡片被悬浮「添加」按钮遮挡。
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: ItemContent(item: item, updatedAt: updatedAt),
    );
  }
}
