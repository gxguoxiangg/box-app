import 'dart:async';
import 'dart:convert';
import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/features/iadb/data/iadb_repository.dart';
import 'package:demo1/features/iadb/models/iadb_models.dart';
import 'package:demo1/features/iadb/viewmodel/iadb_viewmodel.dart';
import 'package:demo1/features/iadb/view/iadb_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> session([
  String token = 'test-access',
  int expires = 900,
]) => {
  'access_token': token,
  'refresh_token': 'test-refresh-$token',
  'expires_in': expires,
  'user': {'username': 'tester'},
};
Map<String, Object?> results({int offset = 0}) => {
  'assets': [
    {
      'asset': {'id': 1, 'name': '测试资产', 'vendor': '测试厂商'},
      'interfaces': [
        {
          'mac_address': 'AA:BB:CC:DD:EE:FF',
          'ip_addresses': [
            {'ip_address': '192.0.2.1'},
          ],
        },
      ],
      'history': [
        {'description': '测试历史'},
      ],
    },
  ],
  'matched_records': [
    {
      'table': 'discovered_device',
      'record': {'id': 2, 'name': '未关联设备'},
    },
  ],
  'matched_asset_count': 1,
  'matched_record_count': 21,
  'offset': offset,
  'limit': 20,
};
http.Response jsonResponse(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
ProviderContainer containerFor(
  FutureOr<http.Response> Function(http.Request) handler,
) {
  final client = ApiClient(
    baseUrl: iadbBaseUrl,
    client: MockClient((request) async => handler(request)),
  );
  final container = ProviderContainer(
    overrides: [iadbApiClientProvider.overrideWithValue(client)],
  );
  addTearDown(() {
    container.dispose();
    client.dispose();
  });
  return container;
}

void main() {
  test('JSON 登录、Bearer、中文和特殊查询字符、204 退出', () async {
    final container = containerFor((request) {
      expect(request.url.origin, iadbBaseUrl);
      if (request.url.path.endsWith('login')) {
        expect(jsonDecode(request.body), {
          'username': 'tester',
          'password': 'test-password',
        });
        return jsonResponse(session());
      }
      expect(request.headers['authorization'], 'Bearer test-access');
      if (request.url.path.endsWith('logout')) return http.Response('', 204);
      expect(request.url.queryParameters['q'], '测试%_');
      return jsonResponse(results());
    });
    final auth = container.read(iadbSessionProvider.notifier);
    await auth.login(' tester ', 'test-password');
    final page = await auth.authorized(
      (token) =>
          container.read(iadbRepositoryProvider).search(token, ' 测试%_ ', 0),
    );
    expect(page.hasNext, isTrue);
    expect(page.assets.single.ips, ['192.0.2.1']);
    expect(page.records.single['table'], 'discovered_device');
    await auth.logout();
    expect(container.read(iadbSessionProvider).value, isNull);
  });
  test('空的成功响应不能作为登录或搜索成功', () {
    expect(() => IadbSession.fromJson({}), throwsA(isA<ApiException>()));
    expect(() => IadbResults.fromJson({}), throwsA(isA<ApiException>()));
  });
  test('并发请求仅刷新一次，使用轮换后的令牌', () async {
    var refreshes = 0;
    final refresh = Completer<http.Response>();
    final container = containerFor((request) {
      if (request.url.path.endsWith('login')) {
        return jsonResponse(session('old', 1));
      }
      if (request.url.path.endsWith('refresh')) {
        refreshes++;
        return refresh.future;
      }
      expect(request.headers['authorization'], 'Bearer new');
      return jsonResponse(results());
    });
    final auth = container.read(iadbSessionProvider.notifier);
    await auth.login('tester', 'test-password');
    final repository = container.read(iadbRepositoryProvider);
    final first = auth.authorized((token) => repository.search(token, 'a', 0));
    final second = auth.authorized((token) => repository.search(token, 'b', 0));
    await Future<void>.delayed(Duration.zero);
    expect(refreshes, 1);
    refresh.complete(jsonResponse(session('new')));
    await Future.wait([first, second]);
    expect(container.read(iadbSessionProvider).value?.accessToken, 'new');
  });
  test('401 只重试一次，刷新失败清空会话', () async {
    var refreshes = 0;
    final container = containerFor((request) {
      if (request.url.path.endsWith('login')) return jsonResponse(session());
      if (request.url.path.endsWith('refresh')) refreshes++;
      return http.Response('{}', 401);
    });
    final auth = container.read(iadbSessionProvider.notifier);
    await auth.login('tester', 'test-password');
    await expectLater(
      auth.authorized(
        (token) => container.read(iadbRepositoryProvider).search(token, 'a', 0),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(refreshes, 1);
    expect(container.read(iadbSessionProvider).value, isNull);
  });
  test('退出后返回的登录响应不会恢复本地会话', () async {
    final pending = Completer<http.Response>();
    final container = containerFor((_) => pending.future);
    final auth = container.read(iadbSessionProvider.notifier);
    final login = auth.login('tester', 'test-password');
    await auth.logout();
    pending.complete(jsonResponse(session()));
    await login;
    expect(container.read(iadbSessionProvider).value, isNull);
  });
  test('清空搜索后忽略未完成的响应', () async {
    final pending = Completer<http.Response>();
    final container = containerFor(
      (request) => request.url.path.endsWith('login')
          ? jsonResponse(session())
          : pending.future,
    );
    final subscription = container.listen(iadbSearchProvider, (_, _) {});
    addTearDown(subscription.close);
    await container
        .read(iadbSessionProvider.notifier)
        .login('tester', 'test-password');
    final model = container.read(iadbSearchProvider.notifier);
    final search = model.search('a');
    model.clear();
    pending.complete(jsonResponse(results()));
    await search;
    expect(container.read(iadbSearchProvider).query, isEmpty);
    expect(container.read(iadbSearchProvider).result.value, isNull);
  });
  for (final brightness in Brightness.values) {
    testWidgets('窄屏 $brightness 登录、搜索、复制和详情', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final container = containerFor(
        (request) => jsonResponse(
          request.url.path.endsWith('login') ? session() : results(),
        ),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const IadbPage(),
          ),
        ),
      );
      expect(find.text('请使用神机账户登录'), findsOneWidget);
      expect(find.text('使用神机账号查询资产，与 Wiki 登录独立'), findsNothing);
      await tester.enterText(find.widgetWithText(TextField, '账号'), 'tester');
      await tester.enterText(
        find.widgetWithText(TextField, '密码'),
        'test-password',
      );
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '测试');
      await tester.tap(find.byTooltip('搜索资产'));
      await tester.pumpAndSettle();
      expect(find.text('测试厂商'), findsOneWidget);
      expect(tester.widget<Text>(find.text('神机')).style?.fontSize, 18);
      expect(
        tester.widget<Text>(find.text('神机')).style?.fontWeight,
        FontWeight.w700,
      );
      expect(
        tester.widget<Text>(find.text('BusyBox 工具魔盒')).style?.fontSize,
        12,
      );
      final owner = tester.getTopLeft(find.text('负责人'));
      final department = tester.getTopLeft(find.text('所属部门'));
      expect(owner.dy, department.dy);
      expect(owner.dx, lessThan(department.dx));
      expect(find.byKey(const ValueKey('iadb-card-footer')), findsOneWidget);
      expect(find.text('命中记录 (21)'), findsOneWidget);
      await tester.tap(find.text('192.0.2.1'));
      await tester.pumpAndSettle();
      expect(copied, '192.0.2.1');
      await tester.tap(find.text('详情'));
      await tester.pumpAndSettle();
      expect(find.text('历史记录 (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('关闭详情'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('切换结果类型'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CheckedPopupMenuItem<bool> && widget.value == true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('discovered_device'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
