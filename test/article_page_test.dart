/// 文章展示页组件测试。
///
/// 使用 MockClient 模拟后端接口，验证完整链路：
/// Repository（网络请求）→ ViewModel（状态）→ ArticleListPage（卡片渲染）→ 搜索过滤。
library;

import 'dart:convert';

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/core/network/api_client_provider.dart';
import 'package:demo1/features/article/view/article_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 构造模拟文章数据的 JSON 响应。
http.Response _articleJson(int id, String title) {
  return http.Response(
    jsonEncode(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'id': id,
        'title': title,
        'level': 2,
        'content': '### Description\n测试正文内容 $id\n### Solutions\n- 方案一',
      },
    }),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

void main() {
  /// 构造一个返回固定两篇文章的 Mock 客户端。
  ApiClient mockApiClient() {
    return ApiClient(
      client: MockClient((http.Request request) async {
        final String path = request.url.path;
        if (path == '/api/article/1') {
          return _articleJson(1, 'Excel 全屏显示');
        }
        if (path == '/api/article/2') {
          return _articleJson(2, 'Word 打印问题');
        }
        return http.Response('{"success": false}', 404);
      }),
    );
  }

  /// 挂载文章页。
  Future<void> pumpArticlePage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 用 MockClient 替换真实网络。
          apiClientProvider.overrideWithValue(mockApiClient()),
        ],
        child: const MaterialApp(home: ArticleListPage()),
      ),
    );
    // 等待异步加载完成（AsyncNotifier.build → Repository → Mock 响应）。
    await tester.pumpAndSettle();
  }

  testWidgets('文章页应加载并展示文章卡片', (WidgetTester tester) async {
    await pumpArticlePage(tester);

    // 第一张卡片（文章 1）可见。
    expect(find.text('Excel 全屏显示'), findsOneWidget);

    // 卡片正文内容（Markdown 标题部分）应渲染。
    expect(find.textContaining('测试正文内容'), findsWidgets);

    // 使用 PageView 实现滑动卡片。
    expect(find.byType(PageView), findsOneWidget);

    // 向左滑动到第二张卡片，验证文章 2 可见。
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Word 打印问题'), findsOneWidget);
  });

  testWidgets('搜索框输入关键词后应按标题过滤', (WidgetTester tester) async {
    await pumpArticlePage(tester);

    // 输入关键词「word」，应只显示 id=2 的文章。
    await tester.enterText(find.byType(TextField), 'word');
    await tester.pumpAndSettle();

    expect(find.text('Word 打印问题'), findsOneWidget);
    expect(find.text('Excel 全屏显示'), findsNothing);

    // 清空关键词，恢复全部。
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Excel 全屏显示'), findsOneWidget);
  });

  testWidgets('接口异常时应展示错误提示与重试按钮', (WidgetTester tester) async {
    // 构造始终抛异常的 Mock 客户端。
    final ApiClient failingClient = ApiClient(
      client: MockClient((http.Request request) async {
        throw http.ClientException('connection refused');
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(failingClient),
        ],
        child: const MaterialApp(home: ArticleListPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 应展示错误信息与「重试」按钮。
    expect(find.textContaining('网络异常'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
