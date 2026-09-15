/// 文章模块 ViewModel（MVVM 的 VM 层）。
///
/// 职责划分：
/// - [articleProvider]：加载整篇文章（含全部条目），供「滑动卡片浏览」；
/// - [articleItemProvider]：按 ID 加载单个条目详情，供搜索结果点击进入；
/// - [articleSearchControllerProvider]：维护搜索关键词，并做防抖触发搜索；
/// - [articleSearchResultProvider]：服务端搜索结果（摘要列表）。
///
/// View 层只订阅这些 Provider，不直接调用 Repository（保证单向数据流）。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/article_repository.dart';
import '../models/article.dart';

// ---------------------------------------------------------------------------
// 1. 文章详情（浏览模式）
// ---------------------------------------------------------------------------

/// 文章加载器（AsyncNotifier）。
///
/// state 为 `AsyncValue<Article>`，自带 loading / error / data 三态。
class ArticleNotifier extends AsyncNotifier<Article> {
  @override
  Future<Article> build() => _fetch();

  /// 调用仓库拉取默认文章。
  Future<Article> _fetch() {
    final ArticleRepository repository = ref.read(articleRepositoryProvider);
    return repository.fetchArticle(AppConstants.defaultArticleId);
  }

  /// 手动刷新（下拉刷新 / 点击重试时调用）。
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

/// 文章详情 Provider。
final articleProvider =
    AsyncNotifierProvider<ArticleNotifier, Article>(ArticleNotifier.new);

// ---------------------------------------------------------------------------
// 2. 单个条目详情（搜索结果点击进入）
// ---------------------------------------------------------------------------

/// 按 ID 加载单个条目详情。
///
/// 采用 family 形式：不同 ID 各自独立加载与缓存，互不影响。
final articleItemProvider =
    FutureProvider.family<ArticleItem, int>((ref, int id) async {
  final ArticleRepository repository = ref.watch(articleRepositoryProvider);
  return repository.fetchItem(id);
});

// ---------------------------------------------------------------------------
// 3. 服务端搜索（关键词 + 防抖 + 结果）
// ---------------------------------------------------------------------------

/// 搜索关键词控制器。
///
/// 输入时立即更新关键词（供 UI 感知「搜索中」），并在停止输入
/// [debounceDuration] 后触发服务端搜索，避免每个字符都发请求。
class ArticleSearchController extends Notifier<String> {
  static const Duration debounceDuration = Duration(milliseconds: 300);

  Timer? _debounce;

  @override
  String build() {
    // 页面销毁时取消未完成的防抖计时器，避免触发已失效的请求。
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  /// 更新搜索关键词。
  void setQuery(String query) {
    state = query;
    _debounce?.cancel();

    final String q = query.trim();
    final ArticleSearchResultNotifier notifier =
        ref.read(articleSearchResultProvider.notifier);

    if (q.isEmpty) {
      // 清空关键词：清空搜索结果，页面回到浏览模式。
      notifier.clear();
      return;
    }

    // 进入「搜索中」状态，随后防抖触发真实请求。
    notifier.markLoading();
    _debounce = Timer(debounceDuration, () {
      notifier.search(q);
    });
  }
}

/// 搜索关键词 Provider。
final articleSearchControllerProvider =
    NotifierProvider<ArticleSearchController, String>(ArticleSearchController.new);

/// 服务端搜索结果加载器。
class ArticleSearchResultNotifier
    extends AsyncNotifier<List<ArticleItemSummary>> {
  /// 请求序号：用于丢弃「过期响应」，避免慢请求覆盖新结果。
  int _requestSeq = 0;

  @override
  Future<List<ArticleItemSummary>> build() async =>
      const <ArticleItemSummary>[];

  /// 清空搜索结果（关键词清空时调用）。
  void clear() {
    _requestSeq++;
    state = const AsyncData(<ArticleItemSummary>[]);
  }

  /// 标记为「搜索中」状态（防抖等待 / 请求进行时）。
  void markLoading() {
    state = const AsyncLoading();
  }

  /// 执行服务端搜索。
  Future<void> search(String query) async {
    final int seq = ++_requestSeq;
    final AsyncValue<List<ArticleItemSummary>> next = await AsyncValue.guard(
      () => ref.read(articleRepositoryProvider).searchItems(query),
    );
    // 仅当本次仍是「最新一次搜索」时才应用结果。
    if (seq == _requestSeq) {
      state = next;
    }
  }
}

/// 服务端搜索结果 Provider。
final articleSearchResultProvider =
    AsyncNotifierProvider<ArticleSearchResultNotifier, List<ArticleItemSummary>>(
        ArticleSearchResultNotifier.new);
