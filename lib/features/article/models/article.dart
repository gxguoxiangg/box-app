/// 文章数据模型。
///
/// 对应知识库后端（backend-doc.md）的返回结构：
/// - [Article]：一篇文章（含嵌套的全部条目），对应 `GET /api/v1/articles/{id}`；
/// - [ArticleItem]：文章下的单个「Q&A」条目，含四章正文（description/causes/
///   solutions/review），对应 `GET /api/v1/items/{id}`；
/// - [ArticleItemSummary]：条目的精简摘要（搜索/列表用），对应
///   `GET /api/v1/items` 与 `GET /api/v1/items?q=` 的 items 元素。
library;

/// 一篇文章。
class Article {
  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 文章 ID。
  final int id;

  /// 文章标题。
  final String title;

  /// 源文件名（后端导入时记录，如 `acticle1.md`）。
  final String sourceFile;

  /// Markdown 源文件的 frontmatter 日期（可选）。
  final DateTime? frontmatterDate;

  /// 入库/更新时间（可作为「最后更新」展示）。
  final DateTime? updatedAt;

  /// 文章标签。
  final List<String> tags;

  /// 条目总数。
  final int itemCount;

  /// 嵌套的全部条目。
  final List<ArticleItem> items;

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const Article({
    required this.id,
    required this.title,
    required this.sourceFile,
    required this.frontmatterDate,
    required this.updatedAt,
    required this.tags,
    required this.itemCount,
    required this.items,
  });

  // ---------------------------------------------------------------------------
  // JSON 解析
  // ---------------------------------------------------------------------------

  /// 从接口返回的 JSON Map 构建 [Article]。
  ///
  /// 字段缺失时提供安全默认值，避免单个字段异常导致整条数据解析失败。
  factory Article.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = (json['items'] as List?) ?? const <dynamic>[];
    return Article(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      sourceFile: (json['source_file'] as String?) ?? '',
      frontmatterDate: DateTime.tryParse((json['frontmatter_date'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      tags: ((json['tags'] as List?) ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      itemCount: (json['item_count'] as num?)?.toInt() ?? rawItems.length,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ArticleItem.fromJson)
          .toList(),
    );
  }
}

/// 文章下的单个条目（一个「Q&A」）。
class ArticleItem {
  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 条目 ID。
  final int id;

  /// 所属文章 ID。
  final int articleId;

  /// 条目在文章中的顺序（从 0 开始）。
  final int position;

  /// 问题标题（如 `Q - Excel 文档全屏显示`）。
  final String question;

  /// 第一章：问题描述（Markdown 文本，可能为空）。
  final String? description;

  /// 第二章：原因分析（Markdown 文本，可能为空）。
  final String? causes;

  /// 第三章：解决方案（Markdown 文本，可能为空）。
  final String? solutions;

  /// 第四章：参考/回顾（Markdown 文本，可能为空）。
  final String? review;

  /// 关键词（Markdown 列表文本，可能为空）。
  final String? keywords;

  // ---------------------------------------------------------------------------
  // 派生字段
  // ---------------------------------------------------------------------------

  /// 去掉「Q - 」前缀后的标题，用于页面大标题与目录展示。
  ///
  /// 后端 `question` 形如 `Q - Excel 文档全屏显示`，前缀「Q - 」是
  /// 导入时的格式化痕迹，展示时应剥离以得到干净的标题。
  String get displayTitle {
    final RegExp prefix = RegExp(r'^Q\s*[-—–:：.]?\s*');
    return question.trim().replaceFirst(prefix, '');
  }

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const ArticleItem({
    required this.id,
    required this.articleId,
    required this.position,
    required this.question,
    required this.description,
    required this.causes,
    required this.solutions,
    required this.review,
    required this.keywords,
  });

  // ---------------------------------------------------------------------------
  // JSON 解析
  // ---------------------------------------------------------------------------

  /// 从接口返回的 JSON Map 构建 [ArticleItem]。
  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    return ArticleItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      articleId: (json['article_id'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt() ?? 0,
      question: (json['question'] as String?) ?? '',
      description: json['description'] as String?,
      causes: json['causes'] as String?,
      solutions: json['solutions'] as String?,
      review: json['review'] as String?,
      keywords: json['keywords'] as String?,
    );
  }
}

/// 条目的精简摘要（搜索 / 列表接口返回）。
class ArticleItemSummary {
  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 条目 ID。
  final int id;

  /// 所属文章 ID。
  final int articleId;

  /// 条目在文章中的顺序（从 0 开始）。
  final int position;

  /// 问题标题。
  final String question;

  /// 是否含图片。
  final bool hasImages;

  /// 是否含代码块。
  final bool hasCode;

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const ArticleItemSummary({
    required this.id,
    required this.articleId,
    required this.position,
    required this.question,
    required this.hasImages,
    required this.hasCode,
  });

  // ---------------------------------------------------------------------------
  // JSON 解析
  // ---------------------------------------------------------------------------

  /// 从接口返回的 JSON Map 构建 [ArticleItemSummary]。
  factory ArticleItemSummary.fromJson(Map<String, dynamic> json) {
    return ArticleItemSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      articleId: (json['article_id'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt() ?? 0,
      question: (json['question'] as String?) ?? '',
      hasImages: (json['has_images'] as bool?) ?? false,
      hasCode: (json['has_code'] as bool?) ?? false,
    );
  }
}
