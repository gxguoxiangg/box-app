/// 主页侧边栏交互测试。
///
/// 覆盖两个关键点：
/// 1. 点击顶部菜单按钮应能打开侧边栏（回归测试「打开无效果」bug）；
/// 2. 侧边栏包含「设置 / 统计 / 关于APP」选项，且点击「关于APP」
///    能跳转到关于页（居中展示应用名称与版本）。
library;

import 'package:demo1/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// 挂载整个应用。
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
  }

  /// 点击菜单按钮打开侧边栏。
  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('点击菜单按钮应打开侧边栏并展示多个选项', (WidgetTester tester) async {
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    await pumpApp(tester);

    // 点击前抽屉不可见。
    expect(find.text('关于APP'), findsNothing);

    // 点击顶部菜单按钮打开侧边栏。
    await openDrawer(tester);

    // 侧边栏应显示全部选项。
    expect(find.text('关于APP'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    final Image logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, 'resource/images/atom.png');
    expect(logo.color, isNull); // 原图包含白底，整体着色会遮住原子图案。
    final Drawer drawer = tester.widget<Drawer>(find.byType(Drawer));
    final RoundedRectangleBorder shape =
        drawer.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));
    final Divider divider = tester.widget<Divider>(
      find
          .descendant(of: find.byType(Drawer), matching: find.byType(Divider))
          .first,
    );
    expect(divider.thickness, 0.5);
    // 状态栏由 Flutter 内容透出；未被抽屉覆盖的顶部也在暗色遮罩范围内。
    expect(SystemChrome.latestStyle?.statusBarColor, Colors.transparent);
    final Finder scrim = find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == Colors.black54,
    );
    final Rect scrimRect = tester.getRect(scrim);
    expect(scrimRect.contains(const Offset(790, 12)), isTrue);
  });

  testWidgets('点击「关于APP」应跳转到关于页并展示名称与版本', (WidgetTester tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    // 点击「关于APP」入口。
    await tester.tap(find.text('关于APP'));
    await tester.pumpAndSettle();

    // 关于页按需求仅显示短名称 BusyBox，并保留版本号。
    expect(find.text('BusyBox'), findsOneWidget);
    expect(find.text('版本 v0.1.0'), findsOneWidget);
  });
}
