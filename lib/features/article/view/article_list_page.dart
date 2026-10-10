/// Wiki 知识库首页。
///
/// 页面提供搜索、关键词筛选和条目列表。点击条目后进入独立阅读页，阅读页
/// 继续复用原有的四章 Markdown 内容展示和目录抽屉。
library;

import 'package:flutter/material.dart';
import 'widgets/wiki_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../../home/data/tool_registry.dart';
import '../../auth/models/auth_session.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/article.dart';
import '../models/keyword_collection.dart';
import '../viewmodel/article_viewmodel.dart';

/// Wiki 知识库首页。
class ArticleListPage extends StatelessWidget {
  /// 创建 Wiki 页面并应用知识库主题。
  const ArticleListPage({super.key});

  @override
  Widget build(BuildContext context) =>
      WikiTheme(child: _ArticleListPageBody());
}

class _ArticleListPageBody extends ConsumerStatefulWidget {
  const _ArticleListPageBody();

  @override
  ConsumerState<_ArticleListPageBody> createState() =>
      _ArticleListPageBodyState();
}

class _ArticleListPageBodyState extends ConsumerState<_ArticleListPageBody> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Provider 可能已经缓存了接口结果，进入页面时仍重新打乱一次顺序。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(articleKeywordsProvider.notifier).shuffle();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = ref.watch(articleSearchControllerProvider);
    final bool searching = query.trim().isNotEmpty;
    final List<ArticleItem> allItems =
        ref.watch(articleProvider).value?.items ?? const <ArticleItem>[];

    return PopScope<void>(
      canPop: !searching,
      onPopInvokedWithResult: (bool didPop, _) {
        // Android 返回键在搜索状态下只退出搜索，避免直接离开 Wiki。
        if (!didPop && searching) _clearSearch();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.surface,
        endDrawer: _buildDirectoryDrawer(allItems),
        floatingActionButton: FloatingActionButton(
          onPressed: _onAddPressed,
          tooltip: '添加',
          child: const Icon(Icons.add_rounded),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(context, searching),
              _buildSearchField(),
              if (!searching) _buildKeywordFilter(),
              Expanded(
                child: searching
                    ? _buildSearchResults(query)
                    : _buildArticleList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建 Wiki 顶部栏。
  Widget _buildHeader(BuildContext context, bool searching) {
    return WikiHeader(
      onBack: _handleBack,
      backLabel: searching ? '返回 Wiki 首页' : '返回主页',
      onDirectory: () => _scaffoldKey.currentState?.openEndDrawer(),
    );
  }

  /// Wiki 首页搜索框，搜索策略继续由 ViewModel 防抖处理。
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索知识库文章、协议、代码...',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '清空搜索',
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: _clearSearch,
                ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        onChanged: (String value) {
          setState(() {});
          ref.read(articleSearchControllerProvider.notifier).setQuery(value);
        },
      ),
    );
  }

  /// 横向滚动的关键词筛选器。
  Widget _buildKeywordFilter() {
    ref.listen<AsyncValue<KeywordCollection>>(articleKeywordsProvider, (
      AsyncValue<KeywordCollection>? previous,
      AsyncValue<KeywordCollection> next,
    ) {
      // 首次异步加载完成后随机一次，覆盖首帧仍处于 loading 的情况。
      if (next.hasValue && previous?.hasValue != true) {
        ref.read(articleKeywordsProvider.notifier).shuffle();
      }
    });
    final AsyncValue<KeywordCollection> keywordsAsync = ref.watch(
      articleKeywordsProvider,
    );
    return SizedBox(
      height: 46,
      child: keywordsAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('关键词暂时不可用', style: TextStyle(color: Colors.grey)),
          ),
        ),
        data: (KeywordCollection collection) => _KeywordChips(
          keywords: collection.keywords,
          items:
              ref.watch(articleProvider).value?.items ?? const <ArticleItem>[],
          selected: ref.watch(articleKeywordControllerProvider),
          onSelected: (String? keyword) {
            ref.read(articleKeywordControllerProvider.notifier).select(keyword);
          },
        ),
      ),
    );
  }

  /// 显示文章条目列表。
  Widget _buildArticleList() {
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
    final List<ArticleItem> items = ref.watch(filteredArticleItemsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CountLabel(count: items.length),
        if (items.isEmpty)
          const Expanded(
            child: Center(
              child: Text('暂无匹配条目', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                return _ArticleListTile(
                  item: items[index],
                  updatedAt: article.updatedAt,
                  onTap: () => _openReader(items[index].id),
                );
              },
            ),
          ),
      ],
    );
  }

  /// 显示服务端搜索结果。
  Widget _buildSearchResults(String query) {
    final AsyncValue<List<ArticleItemSummary>> resultAsync = ref.watch(
      articleSearchResultProvider,
    );
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
        child: Text('未找到相关条目', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final ArticleItemSummary summary = results[index];
        return _SearchResultTile(
          summary: summary,
          onTap: () => _openReader(summary.id),
        );
      },
    );
  }

  /// Wiki 搜索状态下返回首页，首页状态下返回工具盒主页。
  void _handleBack() {
    if (ref.read(articleSearchControllerProvider).trim().isNotEmpty) {
      _clearSearch();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// 清空输入框和搜索 Provider，使页面回到 Wiki 目录首页。
  void _clearSearch() {
    _searchController.clear();
    ref.read(articleSearchControllerProvider.notifier).setQuery('');
    setState(() {});
  }

  /// 进入从当前条目开始的阅读页。
  void _openReader(int itemId) {
    _clearSearch();
    context.push(AppRoutes.articleItemDetailPath(itemId));
  }

  /// Wiki 首页目录抽屉；点击后直接进入对应条目的阅读页。
  Widget _buildDirectoryDrawer(List<ArticleItem> items) {
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      item.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openReader(item.id);
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

  void _onAddPressed() {
    final AuthSession? session = ref
        .read(authSessionProvider.notifier)
        .validSession;
    context.push(session == null ? AppRoutes.login : AppRoutes.articleCreate);
  }
}

/// 条目数量提示，不使用设计稿里的示例数量。
class _CountLabel extends StatelessWidget {
  final int count;
  const _CountLabel({required this.count});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Align(alignment: Alignment.centerLeft, child: WikiTag('共 $count 篇')),
  );
}

/// 筛选项数量来自已加载条目；搜索时不展示无效的筛选操作。
class _KeywordChips extends StatelessWidget {
  final List<String> keywords;
  final List<ArticleItem> items;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _KeywordChips({
    required this.keywords,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => ListView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    children: <Widget>[
      _chip(context, '全部', null, items.length),
      for (final keyword in keywords)
        _chip(
          context,
          '#$keyword',
          keyword,
          items.where((item) => item.keywordList.contains(keyword)).length,
        ),
    ],
  );

  Widget _chip(BuildContext context, String label, String? value, int count) {
    final colors = Theme.of(context).colorScheme;
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        side: BorderSide(
          color: active ? colors.primary : colors.outlineVariant,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: active ? colors.primary : colors.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active ? colors.primary : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: active ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        selected: active,
        onSelected: (_) => onSelected(value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// 列表与搜索共用的卡片排版，只展示服务端提供的元信息。
class _WikiListCard extends StatelessWidget {
  final String title;
  final List<String> keywords;
  final DateTime? updatedAt;
  final VoidCallback onTap;
  const _WikiListCard({
    required this.title,
    required this.onTap,
    this.keywords = const [],
    this.updatedAt,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = updatedAt;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  height: 1.4,
                ),
              ),
              if (keywords.isNotEmpty || date != null) ...<Widget>[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    for (final keyword in keywords) WikiTag('#$keyword'),
                    if (date != null)
                      Text(
                        '更新于 ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleListTile extends StatelessWidget {
  final ArticleItem item;
  final DateTime? updatedAt;
  final VoidCallback onTap;
  const _ArticleListTile({
    required this.item,
    required this.updatedAt,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => _WikiListCard(
    title: item.displayTitle,
    keywords: item.keywordList,
    updatedAt: updatedAt,
    onTap: onTap,
  );
}

class _SearchResultTile extends StatelessWidget {
  final ArticleItemSummary summary;
  final VoidCallback onTap;
  const _SearchResultTile({required this.summary, required this.onTap});
  @override
  Widget build(BuildContext context) =>
      _WikiListCard(title: summary.question, onTap: onTap);
}

/// 后期扩展：作者和分类必须以真实接口字段为基础，不能使用设计稿示例值。
