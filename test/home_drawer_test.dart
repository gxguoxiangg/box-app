/// 主页侧边栏交互测试。
///
/// 覆盖两个关键点：
/// 1. 点击顶部菜单按钮应能打开侧边栏（回归测试「打开无效果」bug）；
/// 2. 侧边栏包含「关于 App / 软件更新 / 全局设置」选项，且点击「关于 App」
///    能跳转到关于页（居中展示应用名称与版本）。
library;

import 'package:demo1/app/app.dart';
import 'package:demo1/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
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
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('点击菜单按钮应打开侧边栏并展示多个选项', (WidgetTester tester) async {
    await pumpApp(tester);

    // 点击前抽屉不可见。
    expect(find.text('关于 App'), findsNothing);

    // 点击顶部菜单按钮打开侧边栏。
    await openDrawer(tester);

    // 侧边栏应显示全部选项。
    expect(find.text('关于 App'), findsOneWidget);
    expect(find.text('软件更新'), findsOneWidget);
    expect(find.text('全局设置'), findsOneWidget);
  });

  testWidgets('点击「关于 App」应跳转到关于页并展示名称与版本', (WidgetTester tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    // 点击「关于 App」入口。
    await tester.tap(find.text('关于 App'));
    await tester.pumpAndSettle();

    // 关于页应居中展示应用名称与版本号（应用名引用常量，避免改名后失效）。
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('版本 v0.1.0'), findsOneWidget);
  });
}
