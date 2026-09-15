/// 文章内容展示页组件测试。
///
/// 使用 MockClient 模拟知识库后端，验证：
/// 1. 浏览模式：加载整篇文章后，以滑动卡片（PageView）展示条目；
/// 2. 目录侧边栏：点击「目录」按钮打开，列出全部标题；
/// 3. 搜索模式：输入关键词触发服务端搜索，结果以列表展示。
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

/// 构造 JSON 响应。
http.Response jsonResponse(Map<String, dynamic> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

/// 模拟文章 1（含 2 个条目）。
Map<String, dynamic> articleJson() {
  return <String, dynamic>{
    'id': 1,
    'title': '桌面问题',
    'updated_at': '2026-08-21T04:13:27.519640Z',
    'items': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'article_id': 1,
        'position': 0,
        'question': 'Q - Excel 文档全屏显示',
        'description': '如何对 xlsx 全屏？',
        'causes': null,
        'solutions': '- WPS：有全屏选项',
        'review': null,
        'keywords': '- WPS',
      },
      <String, dynamic>{
        'id': 2,
        'article_id': 1,
        'position': 1,
        'question': 'Q - Windows 打印问题',
        'description': '打印队列卡住',
        'causes': '驱动问题',
        'solutions': '```powershell\ncmd\n```',
        'review': '参考链接',
        'keywords': null,
      },
    ],
  };
}

void main() {
  /// 构造模拟后端：文章详情 + 服务端搜索。
  ApiClient mockApiClient() {
    return ApiClient(
      client: MockClient((http.Request request) async {
        final String path = request.url.path;
        if (path == '/api/v1/articles/1') {
          return jsonResponse(articleJson());
        }
        if (path == '/api/v1/items' && request.url.queryParameters['q'] != null) {
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
        }
        return http.Response('{}', 404);
      }),
    );
  }

  /// 挂载文章页。
  Future<void> pumpArticlePage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient()),
        ],
        child: const MaterialApp(home: ArticleListPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('浏览模式应加载文章并以滑动卡片展示条目', (WidgetTester tester) async {
    await pumpArticlePage(tester);

    // 第一页（条目 1）标题与章节可见。
    expect(find.text('Excel 文档全屏显示'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Solutions'), findsOneWidget);

    // 使用 PageView 实现左右滑动。
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('点击目录按钮应打开侧边栏并列出全部标题', (WidgetTester tester) async {
    await pumpArticlePage(tester);

    await tester.tap(find.byIcon(Icons.toc_rounded));
    await tester.pumpAndSettle();

    // 侧边栏标题与全部条目标题可见。
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('Excel 文档全屏显示'), findsWidgets);
    expect(find.text('Windows 打印问题'), findsWidgets);
  });

  testWidgets('输入关键词应触发服务端搜索并展示结果', (WidgetTester tester) async {
    await pumpArticlePage(tester);

    await tester.enterText(find.byType(TextField), 'Windows');
    // 等待防抖计时器触发（300ms），再等请求完成。
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // 搜索结果列表展示匹配条目（含「Q - 」前缀）。
    expect(find.text('Q - Windows 打印问题'), findsOneWidget);
  });
}
