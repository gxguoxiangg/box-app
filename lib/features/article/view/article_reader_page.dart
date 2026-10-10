/// Wiki 条目阅读页。
///
/// 保留原有的 PageView + 四章内容展示方式，并支持从指定条目开始打开。
/// 首页点击条目、搜索结果点击和深链进入都会复用此页面。
library;

import 'package:flutter/material.dart';
import 'widgets/wiki_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../../auth/models/auth_session.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../home/data/tool_registry.dart';
import '../models/article.dart';
import '../viewmodel/article_viewmodel.dart';
import 'widgets/article_card.dart';

/// Wiki 条目阅读页。
class ArticleReaderPage extends StatelessWidget {
  /// 创建 Wiki 页面并应用知识库主题。
  const ArticleReaderPage({super.key, required this.initialItemId});

  /// 打开后定位的条目 ID。
  final int initialItemId;
  @override
  Widget build(BuildContext context) =>
      WikiTheme(child: _ArticleReaderPageBody(initialItemId: initialItemId));
}

class _ArticleReaderPageBody extends ConsumerStatefulWidget {
  /// 打开后优先定位的条目 ID。
  final int initialItemId;

  const _ArticleReaderPageBody({required this.initialItemId});

  @override
  ConsumerState<_ArticleReaderPageBody> createState() =>
      _ArticleReaderPageBodyState();
}

class _ArticleReaderPageBodyState
    extends ConsumerState<_ArticleReaderPageBody> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  final ScrollController _tocScrollController = ScrollController();
  int _currentIndex = 0;
  bool _initialPageApplied = false;

  @override
  void dispose() {
    _pageController.dispose();
    _tocScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Article> articleAsync = ref.watch(articleProvider);
    final List<ArticleItem> items =
        articleAsync.value?.items ?? const <ArticleItem>[];

    _applyInitialPage(items);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      endDrawer: _buildTocDrawer(items),
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
            _buildHeader(context),
            Expanded(child: _buildContent(articleAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return WikiHeader(
      backLabel: '返回 Wiki 首页',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.articleList);
        }
      },
      onDirectory: () {
        _scaffoldKey.currentState?.openEndDrawer();
        _scrollDirectoryToCurrent();
      },
    );
  }

  Widget _buildContent(AsyncValue<Article> articleAsync) {
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
    if (article.items.isEmpty) {
      return const Center(child: Text('暂无条目'));
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: article.items.length,
      onPageChanged: (int index) {
        setState(() => _currentIndex = index);
      },
      itemBuilder: (BuildContext context, int index) {
        return ArticleCard(
          item: article.items[index],
          updatedAt: article.updatedAt,
        );
      },
    );
  }

  void _applyInitialPage(List<ArticleItem> items) {
    if (_initialPageApplied || items.isEmpty) return;
    _initialPageApplied = true;
    final int index = items.indexWhere(
      (ArticleItem item) => item.id == widget.initialItemId,
    );
    if (index < 0) return;
    _currentIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    });
  }

  Widget _buildTocDrawer(List<ArticleItem> items) {
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
                controller: _tocScrollController,
                itemExtent: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final ArticleItem item = items[index];
                  final bool selected = index == _currentIndex;
                  return ListTile(
                    selected: selected,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    dense: true,
                    leading: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      item.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pageController.jumpToPage(index);
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

  void _scrollDirectoryToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tocScrollController.hasClients) return;
      final double target = (_currentIndex * 64.0).clamp(
        0.0,
        _tocScrollController.position.maxScrollExtent,
      );
      _tocScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _onAddPressed() {
    final AuthSession? session = ref
        .read(authSessionProvider.notifier)
        .validSession;
    context.push(session == null ? AppRoutes.login : AppRoutes.articleCreate);
  }
}

/// 后期扩展：可以将阅读位置写入本地存储，实现下次打开 Wiki 时恢复上次阅读条目。
