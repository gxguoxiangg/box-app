/// Wiki 投稿仓库测试。
library;

import 'dart:convert';

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/features/article/data/article_submission_repository.dart';
import 'package:demo1/features/article/models/article_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('投稿应携带 Bearer Token 并追加到默认文章', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/push/item');
      expect(request.headers['authorization'], 'Bearer jwt-token');
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['article_id'], 1);
      expect(body['source'], 'flutter-app');
      final Map<String, dynamic> item = (body['item'] as Map<dynamic, dynamic>)
          .cast<String, dynamic>();
      expect(item['question'], '网络故障');
      return http.Response(
        '{"status":"created","item_id":302}',
        201,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final ArticleSubmissionRepository repository = ArticleSubmissionRepository(
      ApiClient(client: client),
    );

    final result = await repository.submit(
      token: 'jwt-token',
      draft: const ArticleDraft(externalKey: 'item:test', question: '网络故障'),
    );

    expect(result.status, 'created');
    expect(result.itemId, 302);
  });

  test('2xx 投稿缺少有效条目时应报告提交无效', () async {
    for (final String body in <String>[
      '{}',
      '{"status":"created","item_id":0}',
      '{"status":"failed","item_id":302}',
      '[]',
    ]) {
      final ApiClient apiClient = ApiClient(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      final ArticleSubmissionRepository repository =
          ArticleSubmissionRepository(apiClient);
      await expectLater(
        repository.submit(
          token: 'jwt-token',
          draft: const ArticleDraft(externalKey: 'item:test', question: '问题'),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            '提交无效',
          ),
        ),
      );
      apiClient.dispose();
    }
  });

  test('2xx 上传没有图片引用时应报告图片上传无效', () async {
    for (final String body in <String>[
      '{"id":0,"url":""}',
      '{"id":43,"url":"not-an-absolute-path"}',
      '[]',
    ]) {
      final ApiClient apiClient = ApiClient(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      final ArticleSubmissionRepository repository =
          ArticleSubmissionRepository(apiClient);
      await expectLater(
        repository.uploadImage(
          token: 'jwt-token',
          bytes: <int>[1, 2, 3],
          filename: 'image.png',
          section: DraftSection.description,
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            '图片上传无效',
          ),
        ),
      );
      apiClient.dispose();
    }
  });

  test('有效图片引用应保留服务端相对路径', () async {
    final ApiClient apiClient = ApiClient(
      client: MockClient(
        (_) async => http.Response('{"id":43,"url":"/media/43.png"}', 201),
      ),
    );
    final ArticleSubmissionRepository repository = ArticleSubmissionRepository(
      apiClient,
    );
    final DraftImage image = await repository.uploadImage(
      token: 'jwt-token',
      bytes: <int>[1, 2, 3],
      filename: 'image.png',
      section: DraftSection.description,
    );
    expect(image.imageId, 43);
    expect(image.url, '/media/43.png');
    apiClient.dispose();
  });
}
