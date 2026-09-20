/// Wiki 登录页面组件测试。
library;

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/core/network/api_client_provider.dart';
import 'package:demo1/features/auth/view/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('错误账号应在密码框下显示指定红色提示',
      (WidgetTester tester) async {
    final ApiClient apiClient = ApiClient(
      client: MockClient((http.Request request) async {
        return http.Response('{"detail":"Unauthorized"}', 401);
      }),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'tester');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    final Finder error = find.text('ⓘ 账号或密码错误。请再试一次');
    expect(error, findsOneWidget);
    expect(tester.widget<Text>(error).style?.color, Colors.red);
  });
}
