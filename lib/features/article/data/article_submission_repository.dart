/// Wiki 条目投稿数据仓库。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../models/article_draft.dart';
import '../models/article_submission.dart';

/// 处理图片上传与条目提交。
class ArticleSubmissionRepository {
  final ApiClient _apiClient;

  const ArticleSubmissionRepository(this._apiClient);

  /// 上传相机图片，返回可附加到草稿的图片引用。
  Future<DraftImage> uploadImage({
    required String token,
    required List<int> bytes,
    required String filename,
    required DraftSection section,
  }) async {
    final Map<String, dynamic> data = await _apiClient.postMultipartImage(
      '${AppConstants.kbApiPrefix}/images/upload',
      bearerToken: token,
      bytes: bytes,
      filename: filename,
      invalidResponseMessage: '图片上传无效',
    );
    final Object? imageId = data['id'];
    final String? url = data['url'] is String
        ? (data['url'] as String).trim()
        : null;
    final Uri? imageUri = url == null ? null : Uri.tryParse(url);
    final bool validUrl =
        imageUri != null &&
        ((imageUri.hasScheme &&
                (imageUri.scheme == 'https' || imageUri.scheme == 'http') &&
                imageUri.host.isNotEmpty) ||
            (!imageUri.hasScheme &&
                url!.startsWith('/') &&
                !url.startsWith('//')));
    if (imageId is! int || imageId <= 0 || !validUrl) {
      throw const ApiException('图片上传无效');
    }
    return DraftImage(
      imageId: imageId,
      section: section.name,
      url: url!,
      altText: filename,
    );
  }

  /// 向默认知识库文章追加一个条目。
  Future<ArticleSubmission> submit({
    required String token,
    required ArticleDraft draft,
  }) async {
    final Map<String, dynamic> data = await _apiClient.postJson(
      '${AppConstants.kbApiPrefix}/push/item',
      <String, dynamic>{
        'article_id': AppConstants.defaultArticleId,
        'source': 'flutter-app',
        'item': draft.toItemJson(),
      },
      bearerToken: token,
      invalidResponseMessage: '提交无效',
    );
    final Object? status = data['status'];
    final Object? itemId = data['item_id'];
    if (status != 'created' || itemId is! int || itemId <= 0) {
      throw const ApiException('提交无效');
    }
    return ArticleSubmission.fromJson(data);
  }
}

/// 投稿仓库 Provider。
final articleSubmissionRepositoryProvider =
    Provider<ArticleSubmissionRepository>((ref) {
      return ArticleSubmissionRepository(ref.watch(apiClientProvider));
    });

/// 后期扩展：如果知识库支持多篇文章，可把 article_id 变为编辑器的显式选择项。
