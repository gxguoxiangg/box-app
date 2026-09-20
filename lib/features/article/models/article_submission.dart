/// Wiki 投稿接口响应模型。
library;

/// 新增条目成功结果。
class ArticleSubmission {
  final String status;
  final int itemId;

  const ArticleSubmission({required this.status, required this.itemId});

  factory ArticleSubmission.fromJson(Map<String, dynamic> json) {
    return ArticleSubmission(
      status: json['status'] as String? ?? '',
      itemId: (json['item_id'] as num?)?.toInt() ?? 0,
    );
  }
}
