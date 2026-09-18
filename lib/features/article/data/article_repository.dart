/// 文章数据仓库（Repository）。
///
/// MVVM 架构中的数据层，屏蔽「数据从哪里来」的细节：
/// 从知识库后端（backend-doc.md 中的 FastAPI 服务）拉取数据，
/// 后期可在此增加本地缓存 / 数据库逻辑，而 ViewModel 与 View 层无需改动。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../models/article.dart';
import '../models/keyword_collection.dart';

/// 文章仓库。
class ArticleRepository {
  final ApiClient _apiClient;

  ArticleRepository(this._apiClient);

  /// 拉取文章详情（含嵌套全部条目）。
  ///
  /// 对应 `GET /api/v1/articles/{id}`，一次请求拿到整篇文章，
  /// 供「滑动卡片浏览 + 目录跳转」使用，避免逐条请求 69 个条目。
  Future<Article> fetchArticle(int id) async {
    final Map<String, dynamic> data = await _apiClient
        .getJson('${AppConstants.kbApiPrefix}/articles/$id');
    return Article.fromJson(data);
  }

  /// 拉取单个条目详情（含四章正文）。
  ///
  /// 对应 `GET /api/v1/items/{id}`，供搜索结果点击进入详情页使用。
  Future<ArticleItem> fetchItem(int id) async {
    final Map<String, dynamic> data =
        await _apiClient.getJson('${AppConstants.kbApiPrefix}/items/$id');
    return ArticleItem.fromJson(data);
  }

  /// 服务端搜索条目。
  ///
  /// 对应 `GET /api/v1/items?q={query}`，返回精简摘要列表（不含正文）。
  /// 采用服务端搜索而非本地过滤，适配知识库后续内容增长（避免全量下载）。
  Future<List<ArticleItemSummary>> searchItems(String query) async {
    final String q = Uri.encodeQueryComponent(query);
    final Map<String, dynamic> data =
        await _apiClient.getJson('${AppConstants.kbApiPrefix}/items?q=$q');
    final List<dynamic> rawItems =
        (data['items'] as List?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(ArticleItemSummary.fromJson)
        .toList();
  }

  /// 获取知识库中全部去重关键词。
  ///
  /// 对应 `GET /api/v1/all-keywords`，接口无需鉴权，供 Wiki 首页筛选器使用。
  Future<KeywordCollection> fetchAllKeywords() async {
    final Map<String, dynamic> data = await _apiClient
        .getJson('${AppConstants.kbApiPrefix}/all-keywords');
    return KeywordCollection.fromJson(data);
  }
}

/// 文章仓库的 Riverpod Provider。
///
/// 依赖 [apiClientProvider]；ViewModel 通过它获取数据。
final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  return ArticleRepository(ref.watch(apiClientProvider));
});
