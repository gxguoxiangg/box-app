/// 文章仓库单元测试。
///
/// 使用 MockClient 模拟知识库后端，验证 [ArticleRepository] 三个方法的
/// 请求路径与解析逻辑：
/// - fetchArticle → `GET /api/v1/articles/{id}`；
/// - fetchItem    → `GET /api/v1/items/{id}`；
/// - searchItems  → `GET /api/v1/items?q={query}`。
library;

import 'dart:convert';

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/features/article/data/article_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 构造 JSON 响应。
http.Response jsonResponse(Map<String, dynamic> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

void main() {
  test('fetchArticle 应请求 /api/v1/articles/{id} 并解析嵌套条目', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/articles/1');
      return jsonResponse(<String, dynamic>{
        'id': 1,
        'title': '桌面问题',
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'question': 'Q - A'},
          <String, dynamic>{'id': 2, 'question': 'Q - B'},
        ],
      });
    });

    final ArticleRepository repo = ArticleRepository(ApiClient(client: client));
    final article = await repo.fetchArticle(1);

    expect(article.title, '桌面问题');
    expect(article.items.length, 2);
  });

  test('fetchItem 应请求 /api/v1/items/{id} 并解析四章正文', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/items/47');
      return jsonResponse(<String, dynamic>{
        'id': 47,
        'question': 'Q - Excel',
        'solutions': '- WPS',
      });
    });

    final ArticleRepository repo = ArticleRepository(ApiClient(client: client));
    final item = await repo.fetchItem(47);

    expect(item.id, 47);
    expect(item.solutions, '- WPS');
  });

  test('searchItems 应请求 /api/v1/items?q= 并解析摘要列表', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/items');
      expect(request.url.queryParameters['q'], 'Windows');
      return jsonResponse(<String, dynamic>{
        'total': 1,
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 2,
            'article_id': 1,
            'position': 1,
            'question': 'Q - Windows 打印问题',
            'has_images': false,
            'has_code': true,
          },
        ],
      });
    });

    final ArticleRepository repo = ArticleRepository(ApiClient(client: client));
    final results = await repo.searchItems('Windows');

    expect(results.length, 1);
    expect(results.first.id, 2);
    expect(results.first.hasCode, true);
  });

  test('fetchAllKeywords 应请求关键词接口并解析去重关键词', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/all-keywords');
      return jsonResponse(<String, dynamic>{
        'total': 2,
        'keywords': <String>['Excel', 'Office'],
      });
    });

    final ArticleRepository repo = ArticleRepository(ApiClient(client: client));
    final collection = await repo.fetchAllKeywords();

    expect(collection.total, 2);
    expect(collection.keywords, <String>['Excel', 'Office']);
  });
}
