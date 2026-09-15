/// 条目详情页组件测试。
///
/// 使用 MockClient 模拟 `GET /api/v1/items/{id}`，验证详情页
/// 按条目 ID 加载并展示标题与四章正文。
library;

import 'dart:convert';

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/core/network/api_client_provider.dart';
import 'package:demo1/features/article/view/item_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('条目详情页应加载并展示标题与章节', (WidgetTester tester) async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/items/47');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'id': 47,
          'article_id': 1,
          'position': 46,
          'question': 'Q - Excel 文档全屏显示',
          'description': '如何对 xlsx 全屏？',
          'causes': null,
          'solutions': '- WPS：有全屏选项',
          'review': '参考链接',
          'keywords': '- WPS',
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
        child: const MaterialApp(home: ItemDetailPage(itemId: 47)),
      ),
    );
    await tester.pumpAndSettle();

    // 标题（剥离「Q - 」前缀）与章节可见。
    expect(find.text('Excel 文档全屏显示'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Solutions'), findsOneWidget);
  });
}
