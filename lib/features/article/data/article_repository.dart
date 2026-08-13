/// 文章数据仓库（Repository）。
///
/// MVVM 架构中的数据层，屏蔽「数据从哪里来」的细节：
/// 目前从远程 API 拉取，后期可在此增加本地缓存 / 数据库逻辑，
/// 而 ViewModel 与 View 层无需改动。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../models/article.dart';

/// 文章仓库。
class ArticleRepository {
  final ApiClient _apiClient;

  ArticleRepository(this._apiClient);

  /// 拉取全部文章。
  ///
  /// 文章 ID 从 1 到 [AppConstants.articleTotal]，逐个请求。
  ///
  /// **实现说明**：
  /// - 并发请求通过 `Future.wait` 并行发出，缩短整体等待时间；
  /// - 采用「部分失败容忍」策略：
  ///   - 部分请求失败 → 跳过失败文章，仍返回成功部分；
  ///   - 全部请求失败 → 抛出首个异常，让 ViewModel 进入错误态
  ///     （比展示空列表更友好，用户可看到明确错误并重试）；
  /// - 返回结果按 ID 升序排序，保证展示顺序稳定。
  Future<List<Article>> fetchAllArticles() async {
    final List<int> ids = List<int>.generate(
      AppConstants.articleTotal,
      (i) => i + 1,
    );

    // 记录首个异常，用于「全部失败」时上抛。
    Object? firstError;

    // 并发请求所有文章；单篇失败时记录异常并返回 null。
    final List<Future<Article?>> futures = ids.map((int id) async {
      try {
        return await _fetchSingleArticle(id);
      } catch (e) {
        firstError ??= e;
        return null;
      }
    }).toList();

    // 等待全部完成，过滤掉失败项。
    final List<Article?> results = await Future.wait(futures);
    final List<Article> articles = results
        .whereType<Article>()
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // 全部失败：抛出首个异常（保留原始错误信息，便于 UI 分类提示）。
    if (articles.isEmpty) {
      if (firstError != null) {
        throw firstError as Exception;
      }
      throw const ApiException('暂无文章数据，请稍后重试');
    }

    return articles;
  }

  /// 拉取单篇文章；失败时抛出异常（由上层统一容错）。
  Future<Article> _fetchSingleArticle(int id) async {
    final Map<String, dynamic> data =
        await _apiClient.getJsonData('${AppConstants.articleEndpoint}$id');
    return Article.fromJson(data);
  }
}

/// 文章仓库的 Riverpod Provider。
///
/// 依赖 [apiClientProvider]；ViewModel 通过它获取数据。
final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  return ArticleRepository(ref.watch(apiClientProvider));
});
