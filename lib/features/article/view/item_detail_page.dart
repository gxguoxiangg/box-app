/// 条目详情页。
///
/// 供「服务端搜索结果」点击后进入，按条目 ID 加载单个条目详情
/// （`GET /api/v1/items/{id}`），展示标题 + 作者/更新时间 + 四章正文。
///
/// 与浏览页（滑动卡片）的区别：
/// - 浏览页：一次加载整篇文章，左右滑动切换条目；
/// - 详情页：按需加载单条，适合搜索结果、外部深链等「直达某一条」的场景。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../models/article.dart';
import '../viewmodel/article_viewmodel.dart';
import 'widgets/item_content.dart';

/// 条目详情页。
class ItemDetailPage extends ConsumerWidget {
  /// 条目 ID。
  final int itemId;

  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ArticleItem> itemAsync = ref.watch(
      articleItemProvider(itemId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('条目详情')),
      body: itemAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (Object error, StackTrace stackTrace) => ErrorRetryView(
          message: error is ApiException ? error.message : '加载失败，请稍后重试',
          onRetry: () => ref.invalidate(articleItemProvider(itemId)),
        ),
        data: (item) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          // 详情接口不含文章级「最后更新」时间，传 null 显示占位。
          child: ItemContent(item: item, updatedAt: null),
        ),
      ),
    );
  }
}
