/// 文章内容展示页（滑动卡片式浏览）。
///
/// 页面结构：
/// 1. 顶部栏：返回按钮 + 标题 + 「目录」按钮（打开侧边栏）；
/// 2. 搜索框：服务端搜索（输入即查询，结果以列表展示，点击进入详情页）；
/// 3. 主体：
///    - 关键词为空 → 滑动卡片（PageView），一页一个条目；
///    - 关键词非空 → 搜索结果列表；
/// 4. 右下角：「添加」按钮（占位，功能待定）。
///
/// MVVM 说明：本页为纯 View，数据与状态全部来自
/// [articleProvider] / [articleSearchControllerProvider] /
/// [articleSearchResultProvider] 等 Provider。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../../home/data/tool_registry.dart';
import '../models/article.dart';
import '../viewmodel/article_viewmodel.dart';
import 'widgets/article_card.dart';

/// 文章内容展示页。
class ArticleListPage extends ConsumerStatefulWidget {
  const ArticleListPage({super.key});

  @override
  ConsumerState<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends ConsumerState<ArticleListPage> {
  /// 用于打开 / 关闭目录侧边栏。
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 滑动卡片控制器（用于目录点击跳转到指定页）。
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = ref.watch(articleSearchControllerProvider);
    final bool searching = query.trim().isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6FA),
      // 「添加」按钮：占位，仅在浏览模式显示（搜索模式不适用）。
      floatingActionButton: searching
          ? null
          : FloatingActionButton(
              onPressed: _onAddPressed,
              tooltip: '添加',
              child: const Icon(Icons.add_rounded),
            ),
      // 目录侧边栏（右侧）。
      endDrawer: _buildTocDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(context, searching),
            _buildSearchField(context),
            Expanded(
              child: searching ? _buildSearchResults(query) : _buildBrowse(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 顶部栏
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, bool searching) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: '返回',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          const Text(
            '文章内容',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // 「目录」按钮：仅在浏览模式显示（搜索模式由结果列表导航）。
          if (!searching)
            IconButton(
              tooltip: '目录',
              icon: const Icon(Icons.toc_rounded, size: 24),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 搜索框
  // ---------------------------------------------------------------------------

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索条目（服务端搜索）',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (String value) {
          ref
              .read(articleSearchControllerProvider.notifier)
              .setQuery(value);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 浏览模式（滑动卡片）
  // ---------------------------------------------------------------------------

  Widget _buildBrowse() {
    final AsyncValue<Article> articleAsync = ref.watch(articleProvider);

    if (articleAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    if (articleAsync.hasError) {
      return ErrorRetryView(
        message: articleAsync.error is ApiException
            ? (articleAsync.error as ApiException).message
            : '加载失败，请稍后重试',
        onRetry: () => ref.read(articleProvider.notifier).refresh(),
      );
    }

    final Article article = articleAsync.value!;
    final List<ArticleItem> items = article.items;

    if (items.isEmpty) {
      return const Center(
        child: Text('暂无条目', style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        return ArticleCard(
          item: items[index],
          updatedAt: article.updatedAt,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 搜索模式（服务端搜索结果）
  // ---------------------------------------------------------------------------

  Widget _buildSearchResults(String query) {
    final AsyncValue<List<ArticleItemSummary>> resultAsync =
        ref.watch(articleSearchResultProvider);

    if (resultAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    if (resultAsync.hasError) {
      return ErrorRetryView(
        message: resultAsync.error is ApiException
            ? (resultAsync.error as ApiException).message
            : '搜索失败，请稍后重试',
        onRetry: () =>
            ref.read(articleSearchResultProvider.notifier).search(query.trim()),
      );
    }

    final List<ArticleItemSummary> results = resultAsync.value ?? const [];

    if (results.isEmpty) {
      return const Center(
        child: Text(
          '未找到相关条目',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final ArticleItemSummary summary = results[index];
        return _SearchResultTile(
          summary: summary,
          onTap: () =>
              context.push(AppRoutes.articleItemDetailPath(summary.id)),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 目录侧边栏
  // ---------------------------------------------------------------------------

  Widget _buildTocDrawer() {
    final List<ArticleItem> items =
        ref.watch(articleProvider).value?.items ?? const <ArticleItem>[];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                '目录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            // 无限下拉：所有标题按序排列，点击跳转到对应页。
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final ArticleItem item = items[index];
                  return ListTile(
                    dense: true,
                    leading: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B6CF6),
                      ),
                    ),
                    title: Text(
                      item.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      // 关闭侧边栏，再跳转到对应页。
                      Navigator.of(context).pop();
                      _jumpToPage(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 跳转到指定下标对应的滑动卡片。
  void _jumpToPage(int index) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  // ---------------------------------------------------------------------------
  // 「添加」按钮（占位）
  // ---------------------------------------------------------------------------

  void _onAddPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('「添加」功能待定，敬请期待')),
    );
  }
}

/// 搜索结果条目（仅展示标题与代码/图片标记）。
class _SearchResultTile extends StatelessWidget {
  final ArticleItemSummary summary;
  final VoidCallback onTap;

  const _SearchResultTile({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  summary.question,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (summary.hasCode) ...<Widget>[
                const SizedBox(width: 8),
                const _TagIcon(icon: Icons.code_rounded, label: '代码'),
              ],
              if (summary.hasImages) ...<Widget>[
                const SizedBox(width: 8),
                const _TagIcon(icon: Icons.image_rounded, label: '图片'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 代码 / 图片标记图标。
class _TagIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TagIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: const Color(0xFF6B7280)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
