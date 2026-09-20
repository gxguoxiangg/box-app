/// Wiki 条目草稿模型。
///
/// 草稿只保存在内存中。模型负责结构化字段、Markdown 总览以及提交 JSON 之间的
/// 转换，页面不直接拼接后端请求体。
library;

/// 编辑器中的正文小节。
enum DraftSection {
  /// 问题标题。
  question('问题标题'),

  /// 具体描述。
  description('具体描述'),

  /// 产生原因。
  causes('产生原因'),

  /// 解决方案。
  solutions('解决方案'),

  /// 复盘。
  review('复盘');

  /// 中文页面标题。
  final String label;

  const DraftSection(this.label);
}

/// 已上传并等待绑定到投稿的图片。
class DraftImage {
  /// 服务端图片 ID。
  final int imageId;

  /// 图片所属正文小节。
  final String section;

  /// 服务端返回的访问路径。
  final String url;

  /// 图片替代文本。
  final String altText;

  const DraftImage({
    required this.imageId,
    required this.section,
    required this.url,
    required this.altText,
  });

  /// 转换为投稿接口要求的图片引用。
  Map<String, dynamic> toJson(int position) => <String, dynamic>{
        'image_id': imageId,
        'section': section,
        'alt_text': altText,
        'position': position,
      };
}

/// 一条待投稿的 Wiki 草稿。
class ArticleDraft {
  /// 重试时保持不变的业务唯一标识。
  final String externalKey;

  final String question;
  final String description;
  final String causes;
  final String solutions;
  final String review;
  final List<String> keywords;
  final List<DraftImage> images;

  const ArticleDraft({
    required this.externalKey,
    this.question = '',
    this.description = '',
    this.causes = '',
    this.solutions = '',
    this.review = '',
    this.keywords = const <String>[],
    this.images = const <DraftImage>[],
  });

  /// 返回指定小节的文本。
  String textFor(DraftSection section) => switch (section) {
        DraftSection.question => question,
        DraftSection.description => description,
        DraftSection.causes => causes,
        DraftSection.solutions => solutions,
        DraftSection.review => review,
      };

  /// 更新一个正文小节。
  ArticleDraft updateText(DraftSection section, String value) => switch (section) {
        DraftSection.question => copyWith(question: value),
        DraftSection.description => copyWith(description: value),
        DraftSection.causes => copyWith(causes: value),
        DraftSection.solutions => copyWith(solutions: value),
        DraftSection.review => copyWith(review: value),
      };

  /// 生成可编辑的 Markdown 总览。
  String get markdownOverview {
    final String keywordMarkdown =
        keywords.isEmpty ? '' : keywords.map((String item) => '- $item').join('\n');
    return <String>[
      '# ${question.trim()}',
      '',
      '## 具体描述',
      description.trim(),
      '',
      '## 产生原因',
      causes.trim(),
      '',
      '## 解决方案',
      solutions.trim(),
      '',
      '## 复盘',
      review.trim(),
      '',
      '## 关键字',
      keywordMarkdown,
    ].join('\n');
  }

  /// 将总览编辑结果重新解析回结构化草稿。
  ///
  /// 标题格式被意外改坏时保留原字段，避免一次编辑清空整份草稿。
  ArticleDraft applyMarkdownOverview(String markdown) {
    String valueAfter(String heading, String? nextHeading) {
      final int start = markdown.indexOf(heading);
      if (start < 0) return '';
      final int contentStart = start + heading.length;
      final int end = nextHeading == null
          ? markdown.length
          : markdown.indexOf(nextHeading, contentStart);
      return markdown
          .substring(contentStart, end < 0 ? markdown.length : end)
          .trim();
    }

    final RegExpMatch? titleMatch = RegExp(r'^#\s+(.+)$', multiLine: true)
        .firstMatch(markdown);
    final String parsedDescription =
        valueAfter('## 具体描述', '## 产生原因');
    final String parsedCauses = valueAfter('## 产生原因', '## 解决方案');
    final String parsedSolutions = valueAfter('## 解决方案', '## 复盘');
    final String parsedReview = valueAfter('## 复盘', '## 关键字');
    final String keywordText = valueAfter('## 关键字', null);
    final List<String> parsedKeywords = keywordText
        .split(RegExp(r'\r?\n'))
        .map((String line) => line.replaceFirst(RegExp(r'^[-*+]\s*'), '').trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return copyWith(
      question: titleMatch?.group(1)?.trim() ?? question,
      description:
          markdown.contains('## 具体描述') ? parsedDescription : description,
      causes: markdown.contains('## 产生原因') ? parsedCauses : causes,
      solutions: markdown.contains('## 解决方案') ? parsedSolutions : solutions,
      review: markdown.contains('## 复盘') ? parsedReview : review,
      keywords: markdown.contains('## 关键字') ? parsedKeywords : keywords,
    );
  }

  /// 转换为 `/push/item` 中的 item 对象。
  Map<String, dynamic> toItemJson() {
    String? nullable(String value) => value.trim().isEmpty ? null : value.trim();
    return <String, dynamic>{
      'external_key': externalKey,
      'question': question.trim(),
      'description': nullable(description),
      'causes': nullable(causes),
      'solutions': nullable(solutions),
      'review': nullable(review),
      'keywords': keywords.isEmpty
          ? null
          : keywords.map((String item) => '- $item').join('\n'),
      'keywords_list': keywords,
      'images': <Map<String, dynamic>>[
        for (int index = 0; index < images.length; index++)
          images[index].toJson(index),
      ],
      'code_blocks': const <Map<String, dynamic>>[],
    };
  }

  ArticleDraft copyWith({
    String? question,
    String? description,
    String? causes,
    String? solutions,
    String? review,
    List<String>? keywords,
    List<DraftImage>? images,
  }) {
    return ArticleDraft(
      externalKey: externalKey,
      question: question ?? this.question,
      description: description ?? this.description,
      causes: causes ?? this.causes,
      solutions: solutions ?? this.solutions,
      review: review ?? this.review,
      keywords: keywords ?? this.keywords,
      images: images ?? this.images,
    );
  }
}

/// 后期扩展：可将草稿序列化到本地数据库，实现崩溃恢复和跨页面继续编辑。
