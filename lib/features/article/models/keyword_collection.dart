/// 知识库关键词集合模型。
///
/// 对应 `GET /api/v1/all-keywords` 接口。关键词由后端统一去重，页面只负责
/// 展示和传递筛选条件，避免客户端重新推断全量关键词。
library;

/// 后端返回的关键词集合。
class KeywordCollection {
  /// 去重后的关键词总数。
  final int total;

  /// 后端返回的关键词列表。
  final List<String> keywords;

  const KeywordCollection({required this.total, required this.keywords});

  /// 从接口 JSON 构建关键词集合。
  factory KeywordCollection.fromJson(Map<String, dynamic> json) {
    final List<String> keywords = ((json['keywords'] as List?) ?? const [])
        .whereType<String>()
        .map((String keyword) => keyword.trim())
        .where((String keyword) => keyword.isNotEmpty)
        .toList(growable: false);
    return KeywordCollection(
      total: (json['total'] as num?)?.toInt() ?? keywords.length,
      keywords: keywords,
    );
  }
}

/// 后期扩展：若关键词接口增加分类、热度或推荐词，可在此模型中扩展字段，
/// 页面和筛选 ViewModel 无需直接依赖后端 JSON 结构。
