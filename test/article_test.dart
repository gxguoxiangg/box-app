/// 文章模块数据模型单元测试。
///
/// 覆盖：
/// 1. [Article.fromJson]：文章与嵌套条目解析、字段容错；
/// 2. [ArticleItem.fromJson]：四章正文与关键词解析、可空字段处理；
/// 3. [ArticleItem.displayTitle]：剥离「Q - 」前缀；
/// 4. [ArticleItemSummary.fromJson]：搜索摘要解析。
library;

import 'package:demo1/features/article/models/article.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArticleItem.fromJson', () {
    test('应正确解析条目完整字段', () {
      final ArticleItem item = ArticleItem.fromJson(<String, dynamic>{
        'id': 47,
        'article_id': 1,
        'position': 46,
        'question': 'Q - Excel 文档全屏显示',
        'description': '如何对 xlsx 全屏？',
        'causes': null,
        'solutions': '- WPS：有全屏选项',
        'review': '参考链接',
        'keywords': '- WPS',
      });

      expect(item.id, 47);
      expect(item.articleId, 1);
      expect(item.position, 46);
      expect(item.question, 'Q - Excel 文档全屏显示');
      expect(item.description, '如何对 xlsx 全屏？');
      expect(item.causes, isNull);
      expect(item.solutions, '- WPS：有全屏选项');
      expect(item.review, '参考链接');
      expect(item.keywords, '- WPS');
    });

    test('可空字段缺失时返回 null，不抛异常', () {
      final ArticleItem item = ArticleItem.fromJson(<String, dynamic>{
        'id': 1,
        'question': 'Q - A',
      });

      expect(item.description, isNull);
      expect(item.causes, isNull);
      expect(item.solutions, isNull);
      expect(item.review, isNull);
    });

    test('字段缺失时应有安全默认值', () {
      final ArticleItem item = ArticleItem.fromJson(<String, dynamic>{});
      expect(item.id, 0);
      expect(item.articleId, 0);
      expect(item.position, 0);
      expect(item.question, '');
    });
  });

  group('ArticleItem.displayTitle', () {
    test('应剥离「Q - 」前缀', () {
      final ArticleItem item =
          ArticleItem.fromJson(<String, dynamic>{'question': 'Q - Excel 文档全屏显示'});
      expect(item.displayTitle, 'Excel 文档全屏显示');
    });

    test('无前缀时原样返回', () {
      final ArticleItem item =
          ArticleItem.fromJson(<String, dynamic>{'question': 'Excel 文档全屏显示'});
      expect(item.displayTitle, 'Excel 文档全屏显示');
    });

    test('空标题返回空字符串', () {
      final ArticleItem item = ArticleItem.fromJson(<String, dynamic>{});
      expect(item.displayTitle, '');
    });
  });

  group('Article.fromJson', () {
    test('应解析文章与嵌套条目', () {
      final Article article = Article.fromJson(<String, dynamic>{
        'id': 1,
        'title': '桌面问题',
        'source_file': 'acticle1.md',
        'updated_at': '2026-08-21T04:13:27.519640Z',
        'tags': <String>['笔记'],
        'item_count': 2,
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'question': 'Q - A'},
          <String, dynamic>{'id': 2, 'question': 'Q - B'},
        ],
      });

      expect(article.id, 1);
      expect(article.title, '桌面问题');
      expect(article.updatedAt, isNotNull);
      expect(article.tags, <String>['笔记']);
      expect(article.items.length, 2);
      expect(article.itemCount, 2);
      expect(article.items.first.question, 'Q - A');
    });

    test('items 缺失时返回空列表，不抛异常', () {
      final Article article = Article.fromJson(<String, dynamic>{'id': 1});
      expect(article.items, isEmpty);
    });
  });

  group('ArticleItemSummary.fromJson', () {
    test('应解析搜索摘要', () {
      final ArticleItemSummary summary =
          ArticleItemSummary.fromJson(<String, dynamic>{
        'id': 2,
        'article_id': 1,
        'position': 1,
        'question': 'Q - Windows 打印问题',
        'has_images': false,
        'has_code': true,
      });

      expect(summary.id, 2);
      expect(summary.question, 'Q - Windows 打印问题');
      expect(summary.hasImages, false);
      expect(summary.hasCode, true);
    });
  });
}
