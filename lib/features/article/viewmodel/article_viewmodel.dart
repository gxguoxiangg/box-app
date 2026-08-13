/// 文章模块 ViewModel（MVVM 的 VM 层）。
///
/// 职责划分：
/// - [articleListProvider]：负责文章数据的异步加载（loading / error / data）；
/// - [articleSearchControllerProvider]：负责搜索关键词状态；
/// - [filteredArticleListProvider]：根据关键词对文章进行本地过滤，供 View 展示。
///
/// View 层只订阅这些 Provider，不直接调用 Repository（保证单向数据流）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/article_repository.dart';
import '../models/article.dart';

// ---------------------------------------------------------------------------
// 1. 文章列表（异步加载）
// ---------------------------------------------------------------------------

/// 文章列表加载器（AsyncNotifier）。
///
/// state 为 `AsyncValue<List<Article>>`，自带 loading / error / data 三种状态，
/// View 层可通过 `ref.watch(articleListProvider)` 直接感知。
class ArticleListNotifier extends AsyncNotifier<List<Article>> {
  @override
  Future<List<Article>> build() {
    // 首次进入页面时自动触发加载。
    return _fetchArticles();
  }

  /// 调用仓库拉取文章列表。
  Future<List<Article>> _fetchArticles() {
    final ArticleRepository repository = ref.read(articleRepositoryProvider);
    return repository.fetchAllArticles();
  }

  /// 手动刷新（下拉刷新 / 点击重试时调用）。
  ///
  /// 使用 [AsyncValue.guard] 将异常包装为 error 状态，供 UI 展示。
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchArticles);
  }
}

/// 文章列表 Provider。
///
/// Riverpod 3 中所有 Provider 默认 autoDispose：离开页面后自动释放，
/// 再次进入时重新加载，保证数据不过期。
final articleListProvider =
    AsyncNotifierProvider<ArticleListNotifier, List<Article>>(
        ArticleListNotifier.new);

// ---------------------------------------------------------------------------
// 2. 搜索关键词（本地过滤）
// ---------------------------------------------------------------------------

/// 搜索关键词控制器。
///
/// 目前为本地过滤（按标题匹配）。后期若接口支持服务端搜索，
/// 只需在此将过滤逻辑下沉到 Repository，View 无需改动。
class ArticleSearchController extends Notifier<String> {
  @override
  String build() => '';

  /// 更新搜索关键词。
  void setQuery(String query) => state = query;
}

/// 搜索关键词 Provider。
final articleSearchControllerProvider =
    NotifierProvider<ArticleSearchController, String>(ArticleSearchController.new);

// ---------------------------------------------------------------------------
// 3. 过滤后的文章列表（供 View 使用）
// ---------------------------------------------------------------------------

/// 根据搜索关键词过滤后的文章列表。
///
/// - 关键词为空：返回全部文章；
/// - 关键词非空：按标题包含匹配（可扩展为正文匹配 / 拼音匹配等）。
final filteredArticleListProvider = Provider<List<Article>>((ref) {
  // 数据加载中 / 失败时，以空列表兜底，避免过滤逻辑报错。
  // 说明：Riverpod 3 中 AsyncValue 使用 `.value` 获取可空数据（valueOrNull 已移除）。
  final List<Article> articles =
      ref.watch(articleListProvider).value ?? const <Article>[];
  final String query = ref.watch(articleSearchControllerProvider);

  return filterArticles(articles, query);
});

/// 按关键词过滤文章的纯函数。
///
/// 独立成纯函数（不依赖 Riverpod），便于单元测试与后期扩展
/// （例如改为多字段匹配、服务端搜索时，只需修改此处）。
List<Article> filterArticles(List<Article> articles, String query) {
  final String q = query.trim();
  if (q.isEmpty) return articles;
  return articles
      .where((Article a) => a.title.toLowerCase().contains(q.toLowerCase()))
      .toList();
}
