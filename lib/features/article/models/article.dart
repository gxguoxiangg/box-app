/// 文章数据模型。
///
/// 对应后端接口返回的 `data` 字段结构：
/// ```json
/// { "id": 1, "title": "...", "level": 2, "content": "...markdown..." }
/// ```
library;

/// 一篇文章。
class Article {
  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 文章 ID（对应接口 `/api/article/{id}`）。
  final int id;

  /// 文章标题。
  final String title;

  /// 文章难度 / 级别（数字越大难度越高，可用于后续排序筛选）。
  final int level;

  /// 文章正文内容（服务端返回 Markdown 格式文本）。
  final String content;

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const Article({
    required this.id,
    required this.title,
    required this.level,
    required this.content,
  });

  // ---------------------------------------------------------------------------
  // JSON 解析
  // ---------------------------------------------------------------------------

  /// 从接口返回的 JSON Map 构建 [Article]。
  ///
  /// 字段缺失时提供安全默认值，避免单个字段异常导致整条数据解析失败。
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      content: (json['content'] as String?) ?? '',
    );
  }

  /// 转换为 JSON Map（供后续本地缓存 / 序列化使用）。
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'level': level,
      'content': content,
    };
  }
}
