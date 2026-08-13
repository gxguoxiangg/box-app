/// 文章内容展示页。
///
/// 「滑动卡片式」布局：使用 PageView 实现左右滑动切换文章卡片，
/// 每张卡片展示一篇文章的完整内容。
///
/// 页面结构：
/// 1. 顶部栏：返回按钮 + 标题 + 搜索框（按标题本地过滤，已实现）；
/// 2. 主体：文章卡片滑动区（含加载 / 错误 / 数据三态）；
/// 3. 底部：页码指示点。
///
/// MVVM 说明：本页为纯 View，数据与状态全部来自
/// [articleListProvider] / [filteredArticleListProvider] 等 Provider。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
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
  /// 当前滑到的卡片下标（用于页码指示点）。
  int _currentIndex = 0;

  /// 当前展示的文章列表缓存（避免过滤变化时 PageView 抖动）。
  List<Article> _displayed = const <Article>[];

  @override
  Widget build(BuildContext context) {
    // 订阅过滤后的文章列表（数据 + 搜索关键词共同决定）。
    final List<Article> articles = ref.watch(filteredArticleListProvider);
    // 订阅原始加载状态（判断 loading / error）。
    final AsyncValue<List<Article>> asyncState = ref.watch(articleListProvider);

    // 搜索 / 数据变化时，重置页码。
    if (_displayed != articles) {
      _displayed = articles;
      _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // -----------------------------------------------------------------
            // 顶部栏：返回 + 标题 + 搜索框
            // -----------------------------------------------------------------
            _buildHeader(context),

            // -----------------------------------------------------------------
            // 主体：根据状态渲染
            // -----------------------------------------------------------------
            Expanded(child: _buildBody(context, asyncState, articles)),
          ],
        ),
      ),
    );
  }

  /// 顶部栏。
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              // 返回按钮
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
            ],
          ),
          const SizedBox(height: 4),
          // 搜索框：输入即过滤（走 ViewModel 本地过滤）。
          _buildSearchField(context),
        ],
      ),
    );
  }

  /// 搜索框。
  Widget _buildSearchField(BuildContext context) {
    return TextField(
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索文章标题',
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
      // 每次输入将关键词同步到 ViewModel，触发过滤后的列表更新。
      onChanged: (String value) {
        ref
            .read(articleSearchControllerProvider.notifier)
            .setQuery(value);
      },
    );
  }

  /// 根据异步状态渲染主体区域。
  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<Article>> asyncState,
    List<Article> articles,
  ) {
    // 加载中
    if (asyncState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    // 加载失败：展示错误信息 + 重试按钮
    if (asyncState.hasError) {
      final Object? error = asyncState.error;
      return _ErrorView(
        message: error is ApiException
            ? error.message
            : '加载失败，请稍后重试',
        onRetry: () => ref.read(articleListProvider.notifier).refresh(),
      );
    }

    // 搜索无结果
    if (articles.isEmpty) {
      return const Center(
        child: Text(
          '未找到相关文章',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    // 正常展示：滑动卡片
    return Column(
      children: <Widget>[
        Expanded(
          child: PageView.builder(
            itemCount: articles.length,
            // 滑动切换卡片，同步更新页码指示点。
            onPageChanged: (int index) =>
                setState(() => _currentIndex = index),
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: ArticleCard(
                  article: articles[index],
                  index: index + 1,
                ),
              );
            },
          ),
        ),
        // 页码指示点
        _buildPageIndicator(articles.length),
      ],
    );
  }

  /// 页码指示点。
  Widget _buildPageIndicator(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(total, (int index) {
          final bool active = index == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF3B6CF6) : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

/// 加载失败视图：错误信息 + 重试按钮。
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
