/// Wiki 七步条目编辑器组件测试。
library;

import 'dart:convert';

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/core/network/api_client_provider.dart';
import 'package:demo1/features/article/view/article_create_page.dart';
import 'package:demo1/features/auth/models/auth_session.dart';
import 'package:demo1/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('编辑器应按七张卡片进入可编辑总览', (WidgetTester tester) async {
    final ApiClient apiClient = ApiClient(
      client: MockClient((http.Request request) async {
        if (request.url.path == '/api/v1/all-keywords') {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'total': 2,
              'keywords': <String>['网络', '打印机'],
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(apiClient)],
    );
    addTearDown(container.dispose);
    container
        .read(authSessionProvider.notifier)
        .setSession(
          AuthSession(
            accessToken: 'jwt-token',
            tokenType: 'bearer',
            expiresIn: 3600,
            username: 'tester',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ArticleCreatePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('问题标题'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, '网络故障');

    for (int page = 1; page < 7; page++) {
      await tester.tap(find.byTooltip('下一张卡片'));
      await tester.pumpAndSettle();
    }

    expect(find.text('7 / 7'), findsOneWidget);
    expect(find.text('文章预览'), findsOneWidget);
    expect(find.text('编辑 Markdown 总览'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('提交'), findsOneWidget);
    expect(find.text('删除草稿'), findsOneWidget);
    container.read(authSessionProvider.notifier).clear();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('服务端返回无效投稿结果时编辑器显示提交无效并保留草稿', (WidgetTester tester) async {
    final ApiClient apiClient = ApiClient(
      client: MockClient((http.Request request) async {
        if (request.url.path == '/api/v1/all-keywords') {
          return http.Response('{"total":0,"keywords":[]}', 200);
        }
        if (request.url.path == '/api/v1/push/item') {
          return http.Response('{}', 200);
        }
        return http.Response('{}', 404);
      }),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(apiClient)],
    );
    addTearDown(() {
      container.dispose();
      apiClient.dispose();
    });
    container
        .read(authSessionProvider.notifier)
        .setSession(
          AuthSession(
            accessToken: 'jwt-token',
            tokenType: 'bearer',
            expiresIn: 3600,
            username: 'tester',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ArticleCreatePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '网络故障');
    for (int page = 1; page < 7; page++) {
      await tester.tap(find.byTooltip('下一张卡片'));
      await tester.pumpAndSettle();
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '提交').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('提交无效'), findsOneWidget);
    expect(find.text('新增 Wiki 条目'), findsOneWidget);

    container.read(authSessionProvider.notifier).clear();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
