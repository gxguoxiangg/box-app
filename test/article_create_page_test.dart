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
import 'package:super_editor/super_editor.dart';

void main() {
  testWidgets('Markdown 正文使用单一所见即所得编辑区域', (WidgetTester tester) async {
    final ApiClient apiClient = ApiClient(
      client: MockClient((_) async => http.Response('{"keywords":[]}', 200)),
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
    await tester.tap(find.byTooltip('下一张卡片'));
    await tester.pumpAndSettle();
    expect(find.byType(SuperEditor), findsOneWidget);
    expect(find.text('实时预览'), findsNothing);
    expect(find.byTooltip('加粗'), findsOneWidget);
    expect(find.byTooltip('有序列表'), findsOneWidget);
    expect(find.byTooltip('无序列表'), findsOneWidget);

    container.read(authSessionProvider.notifier).clear();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('编辑器应按七张卡片进入可编辑总览', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
      if (page == 5) {
        await tester.tap(find.text('#网络'));
        await tester.pumpAndSettle();
        expect(find.text('已选标签 (1)'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }

    expect(find.text('7 / 7'), findsOneWidget);
    expect(find.text('文章实际渲染效果预览'), findsOneWidget);
    expect(find.text('#网络'), findsOneWidget);
    expect(find.byType(SuperEditor), findsNothing);
    await tester.tap(find.text('编辑总览'));
    await tester.pumpAndSettle();
    expect(find.text('文章总览（可直接编辑）'), findsOneWidget);
    expect(find.byType(SuperEditor), findsOneWidget);
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
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '提交').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('提交无效'), findsOneWidget);
    expect(find.text('新增文章'), findsOneWidget);

    container.read(authSessionProvider.notifier).clear();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
