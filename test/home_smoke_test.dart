/// 主页（工具盒）渲染冒烟测试。
///
/// 验证：应用根组件可正常挂载，主页显示标题与工具按钮。
library;

import 'package:demo1/app/app.dart';
import 'package:demo1/core/theme/busybox_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('首次进入先显示品牌文字，停留一秒后才播放动画', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('GuoXiang'), findsOneWidget);
    expect(find.text(' BusyBox'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 999));
    expect(find.text('GuoXiang'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('GuoXiang'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('主页'), findsOneWidget);
  });

  testWidgets('主页应渲染网络摘要、常用工具与全部工具', (WidgetTester tester) async {
    // 挂载整个应用（ProviderScope 是 App 正常运行的前提）。
    await tester.pumpWidget(const ProviderScope(child: App()));

    // 定时器不会被 pumpAndSettle 自动快进；先走过品牌文字停留的一秒。
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // 1. 首次进入动画结束后，顶部栏显示“主页”。
    expect(find.text('主页'), findsOneWidget);

    // 新版主页显示网络摘要及常用工具入口。
    expect(find.text('当前网络信息'), findsOneWidget);
    expect(find.text('常用工具'), findsOneWidget);
    expect(find.text('自定义'), findsOneWidget);

    // 常用工具仍包含 Wiki。
    expect(find.text('Wiki'), findsOneWidget);

    // 工具按钮为可点击区域。
    final Finder toolFinder = find.text('Wiki');
    expect(tester.widget<Text>(toolFinder).style?.fontWeight, isNotNull);
    final Finder wikiIcon = find.descendant(
      of: find.byKey(const ValueKey<String>('quick-tool-wiki')),
      matching: find.byType(Icon),
    );
    expect(tester.widget<Icon>(wikiIcon).color, BusyBoxPalette.light.accent);

    // 全部工具位于滚动区域下方，滑动后再验证。
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('全部工具'), findsOneWidget);
  });
}
