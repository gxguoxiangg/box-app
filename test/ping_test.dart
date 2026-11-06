import 'package:demo1/features/ping/data/ping_output.dart';
import 'dart:async';
import 'dart:convert';
import 'package:demo1/core/theme/busybox_palette.dart';
import 'package:demo1/features/ping/models/ping_models.dart';
import 'package:demo1/features/ping/data/ping_repository.dart';
import 'package:demo1/features/ping/data/ping_transport.dart';
import 'package:demo1/features/ping/viewmodel/ping_viewmodel.dart';
import 'package:demo1/features/ping/view/ping_page.dart';
import 'package:demo1/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePing implements PingTransport {
  FakePing({this.available = true});
  final bool available;
  final pending = <Completer<double?>>[];
  int cancellations = 0;
  @override
  bool get supported => available;
  @override
  Future<double?> probe(String target, int bytes, int timeoutMs) {
    final c = Completer<double?>();
    pending.add(c);
    return c.future;
  }

  @override
  void cancel() {
    cancellations++;
  }
}

void main() {
  testWidgets('历史时间位于指标下方，零丢包使用绿色', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final record = jsonEncode({
      'time': '2026-11-03T12:34:56.123',
      'report': 'test',
      'bytes': 64,
      'targets': [
        {
          'target': '192.0.2.1',
          'sent': 4,
          'received': 4,
          'average': 247.57,
          'loss': 0,
        },
      ],
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pingTransportProvider.overrideWithValue(FakePing()),
          pingHistoryProvider.overrideWith((ref) async => [record]),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const PingPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('2026-11-03 12:34:56'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final loss = find.text('0%');
    final avgBox = find
        .ancestor(of: find.text('247.57 ms'), matching: find.byType(Container))
        .first;
    final lossBox = find
        .ancestor(of: loss, matching: find.byType(Container))
        .first;
    expect(tester.getSize(avgBox), tester.getSize(lossBox));
    expect(tester.getTopLeft(avgBox).dy, tester.getTopLeft(lossBox).dy);
    expect(
      tester.widget<Text>(loss).style?.color,
      BusyBoxPalette.light.success,
    );
    expect(
      tester.getTopLeft(find.text('2026-11-03 12:34:56')).dy,
      greaterThan(tester.getTopLeft(loss).dy),
    );
    expect(find.textContaining('T12:34'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test('系统回包解析，不把汇总或错误当成功', () {
    expect(
      parsePingLatency(
        '64 bytes from 192.0.2.1: icmp_seq=1 ttl=64 time=2.35 ms',
      ),
      2.35,
    );
    expect(parsePingLatency('time<1 ms'), 1);
    expect(
      () => parsePingLatency(
        '1 packets transmitted, 0 received, 100% packet loss',
      ),
      throwsFormatException,
    );
    expect(() => parsePingLatency('permission denied'), throwsFormatException);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('目标与参数严格校验', () {
    for (final target in ['8.8.8.8', 'baidu.com', 'my-router']) {
      expect(PingConfig([target]).error, isNull);
    }
    for (final target in [
      '256.1.1.1',
      '-c',
      'a;id',
      'a b',
      'https://a.com',
      '',
      '1.2.3',
    ]) {
      expect(PingConfig([target]).error, isNotNull);
    }
    expect(const PingConfig(['a', 'a']).error, isNotNull);
    expect(const PingConfig(['a'], count: 101).error, isNotNull);
    expect(const PingConfig(['a'], timeoutMs: 0).error, isNotNull);
  });
  test('统计忽略超时，不将其视为零延迟', () {
    const r = PingTargetResult('a', [
      PingSample(1, 10),
      PingSample(2, null),
      PingSample(3, 30),
    ]);
    expect(r.received, 2);
    expect(r.sent, 3);
    expect(r.average, 20);
    expect(r.mdev, 10);
    expect(r.loss, closeTo(100 / 3, 0.001));
    expect(r.minimum, 10);
    expect(r.maximum, 30);
    expect(const PingTargetResult('a', []).loss, isNull);
  });
  test('多目标实时更新，完成保存历史', () async {
    final fake = FakePing();
    final c = ProviderContainer(
      overrides: [pingTransportProvider.overrideWithValue(fake)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(pingRunProvider, (_, _) {});
    addTearDown(sub.close);
    final run = c
        .read(pingRunProvider.notifier)
        .start(const PingConfig(['a', 'b'], count: 1));
    fake.pending[0].complete(12);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(pingRunProvider).results[0].received, 1);
    expect(c.read(pingRunProvider).running, true);
    fake.pending[1].complete(null);
    await run;
    expect(c.read(pingRunProvider).results[1].loss, 100);
    expect(c.read(pingRunProvider).running, false);
    expect(await c.read(pingHistoryRepositoryProvider).read(), hasLength(1));
  });
  test('停止与重启隔离旧回包', () async {
    final fake = FakePing();
    final c = ProviderContainer(
      overrides: [pingTransportProvider.overrideWithValue(fake)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(pingRunProvider, (_, _) {});
    addTearDown(sub.close);
    final vm = c.read(pingRunProvider.notifier);
    final old = vm.start(const PingConfig(['a'], count: 1));
    vm.stop();
    final fresh = vm.start(const PingConfig(['b'], count: 1));
    fake.pending[0].complete(999);
    await old;
    expect(c.read(pingRunProvider).results.single.target, 'b');
    expect(c.read(pingRunProvider).results.single.sent, 0);
    fake.pending[1].complete(5);
    await fresh;
    expect(c.read(pingRunProvider).results.single.average, 5);
  });
  test('释放结果页取消探测且不保存未完成结果', () async {
    final fake = FakePing();
    final c = ProviderContainer(
      overrides: [pingTransportProvider.overrideWithValue(fake)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(pingRunProvider, (_, _) {});
    final run = c
        .read(pingRunProvider.notifier)
        .start(const PingConfig(['a'], count: 1));
    sub.close();
    await c.pump();
    fake.pending.single.complete(1);
    await run;
    expect(fake.cancellations, greaterThan(1));
    expect(await c.read(pingHistoryRepositoryProvider).read(), isEmpty);
  });
  test('历史持久化上限及清除', () async {
    final repo = PingHistoryRepository();
    for (var i = 0; i < 52; i++) {
      await repo.save('report$i');
    }
    expect(await PingHistoryRepository().read(), hasLength(50));
    expect((await repo.read()).first, contains('report51'));
    await repo.clear();
    expect(await repo.read(), isEmpty);
  });
  for (final dark in [false, true]) {
    testWidgets('320px 输入页与真实结果布局 dark=$dark', (tester) async {
      tester.view.physicalSize = const Size(320, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakePing();
      final c = ProviderContainer(
        overrides: [pingTransportProvider.overrideWithValue(fake)],
      );
      addTearDown(c.dispose);
      Widget app(Widget page) => UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: page,
        ),
      );
      await tester.pumpWidget(app(const PingPage()));
      await tester.pumpAndSettle();
      expect(find.text('暂无测试历史'), findsOneWidget);
      expect(
        tester.getCenter(find.text('233.5.5.5')).dy,
        tester.getCenter(find.text('baidu.com')).dy,
      );
      await tester.tap(find.text('233.5.5.5'));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('ping-target-0')))
            .controller
            ?.text,
        '233.5.5.5',
      );
      final hint = tester
          .widget<TextField>(find.byKey(const ValueKey('ping-target-0')))
          .decoration
          ?.hintStyle;
      expect(hint?.fontWeight, FontWeight.w400);
      await tester.tap(find.text('添加测试目标'));
      await tester.pump();
      expect(find.byKey(const ValueKey('ping-target-1')), findsOneWidget);
      await tester.pumpWidget(
        app(const PingResultPage(config: PingConfig(['8.8.8.8'], count: 1))),
      );
      await tester.pump();
      expect(find.textContaining('探测进行中'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('等待完成'), findsOneWidget);
      final export = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, '等待完成'),
      );
      expect(export.onPressed, isNull);
      expect(
        tester.getCenter(find.widgetWithText(OutlinedButton, '终止本次探测')).dy,
        tester.getCenter(find.widgetWithText(OutlinedButton, '等待完成')).dy,
      );
      fake.pending.single.complete(2.5);
      await tester.pumpAndSettle();
      expect(find.textContaining('测试完成'), findsOneWidget);
      expect(find.text('延迟趋势'), findsOneWidget);
      await tester.ensureVisible(find.text('导出诊断报告'));
      await tester.tap(find.text('导出诊断报告'));
      await tester.pumpAndSettle();
      expect(find.text('导出或分享测试报告'), findsOneWidget);
      expect(find.text('微信'), findsOneWidget);
      expect(find.text('保存图片'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('导出或分享测试报告'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('非Android提示不支持', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pingTransportProvider.overrideWithValue(FakePing(available: false)),
        ],
        child: const MaterialApp(home: PingPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂仅支持 Android 真实 ICMP Ping'), findsOneWidget);
  });
}
