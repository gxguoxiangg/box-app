/// 文章模块单元测试。
///
/// 覆盖：
/// 1. [Article.fromJson] 的 JSON 解析与字段容错；
/// 2. [filterArticles] 搜索过滤逻辑。
library;

import 'package:demo1/features/article/models/article.dart';
import 'package:demo1/features/article/viewmodel/article_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

/// 构造一个测试文章。
Article _article(int id, String title) {
  return Article(id: id, title: title, level: 2, content: 'content-$id');
}

void main() {
  group('Article.fromJson', () {
    test('应正确解析接口返回的 JSON 数据', () {
      final Article article = Article.fromJson(const <String, dynamic>{
        'id': 1,
        'title': 'Excel 文档全屏显示',
        'level': 2,
        'content': '### Description\n正文内容',
      });

      expect(article.id, 1);
      expect(article.title, 'Excel 文档全屏显示');
      expect(article.level, 2);
      expect(article.content, contains('### Description'));
    });

    test('字段缺失时应有安全默认值，不抛异常', () {
      final Article article = Article.fromJson(const <String, dynamic>{});
      expect(article.id, 0);
      expect(article.title, '');
      expect(article.level, 0);
      expect(article.content, '');
    });
  });

  group('filterArticles', () {
    final List<Article> articles = <Article>[
      _article(1, 'Excel 全屏显示'),
      _article(2, 'Word 打印问题'),
      _article(3, 'Office 安装教程'),
    ];

    test('关键词为空时返回全部文章', () {
      final List<Article> result = filterArticles(articles, '');
      expect(result.length, 3);
    });

    test('关键词仅为空白字符时同样返回全部', () {
      final List<Article> result = filterArticles(articles, '   ');
      expect(result.length, 3);
    });

    test('按标题包含匹配过滤', () {
      final List<Article> result = filterArticles(articles, 'office');
      // 大小写不敏感：应匹配 id=3 的 Office。
      expect(result.map((a) => a.id), <int>[3]);
    });

    test('无匹配时返回空列表', () {
      final List<Article> result = filterArticles(articles, '不存在的关键词');
      expect(result, isEmpty);
    });
  });
}
