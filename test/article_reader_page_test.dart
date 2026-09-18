/// Wiki 阅读页组件测试。
///
/// 使用 MockClient 返回整篇文章，验证从首页或搜索结果进入阅读页时，
/// PageView 会从指定条目开始，而不是固定从第一篇开始。
library;

import 'dart:convert';

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/core/network/api_client_provider.dart';
import 'package:demo1/features/article/view/article_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('阅读页应从传入的当前条目开始并显示 Wiki 顶栏',
      (WidgetTester tester) async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/articles/1');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'id': 1,
          'updated_at': '2026-08-28T00:00:00Z',
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'question': 'Q - 第一条',
              'description': '第一条内容',
            },
            <String, dynamic>{
              'id': 2,
              'question': 'Q - 当前条目',
              'description': '当前内容',
            },
          ],
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: client)),
        ],
        child: const MaterialApp(
          home: ArticleReaderPage(initialItemId: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wiki'), findsOneWidget);
    expect(find.text('当前条目'), findsOneWidget);
    expect(find.text('当前内容'), findsOneWidget);
    expect(find.text('第一条内容'), findsNothing);

    await tester.tap(find.byIcon(Icons.toc_rounded));
    await tester.pumpAndSettle();
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('当前条目'), findsWidgets);
  });
}
