/// Wiki 阅读页组件测试。
///
/// 使用 MockClient 返回整篇文章，验证从首页或搜索结果进入阅读页时，
/// PageView 会从指定条目开始，而不是固定从第一篇开始。
library;

import 'dart:convert';

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/core/network/api_client_provider.dart';
import 'package:demo1/features/auth/models/auth_session.dart';
import 'package:demo1/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:demo1/features/home/data/tool_registry.dart';
import 'package:demo1/features/article/view/article_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('阅读页应从传入的当前条目开始并显示 Wiki 顶栏', (WidgetTester tester) async {
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
        child: const MaterialApp(home: ArticleReaderPage(initialItemId: 2)),
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

  for (final bool loggedIn in <bool>[false, true]) {
    testWidgets('阅读页添加按钮按登录状态进入${loggedIn ? '投稿' : '登录'}页', (
      WidgetTester tester,
    ) async {
      final ApiClient apiClient = ApiClient(
        client: MockClient(
          (_) async => http.Response('{"id":1,"items":[]}', 200),
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      final GoRouter router = GoRouter(
        initialLocation: '/read',
        routes: [
          GoRoute(
            path: '/read',
            builder: (_, _) => const ArticleReaderPage(initialItemId: 1),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (_, _) => const Scaffold(body: Text('登录页')),
          ),
          GoRoute(
            path: AppRoutes.articleCreate,
            builder: (_, _) => const Scaffold(body: Text('投稿页')),
          ),
        ],
      );
      addTearDown(() {
        router.dispose();
        container.dispose();
        apiClient.dispose();
      });
      if (loggedIn) {
        container
            .read(authSessionProvider.notifier)
            .setSession(
              AuthSession(
                accessToken: 'token',
                tokenType: 'bearer',
                expiresIn: 3600,
                username: 'tester',
                expiresAt: DateTime.now().add(const Duration(hours: 1)),
              ),
            );
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('添加'));
      await tester.pumpAndSettle();
      expect(find.text(loggedIn ? '投稿页' : '登录页'), findsOneWidget);
      if (loggedIn) container.read(authSessionProvider.notifier).clear();
    });
  }
}
