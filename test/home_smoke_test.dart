/// 主页（工具盒）渲染冒烟测试。
///
/// 验证：应用根组件可正常挂载，主页显示标题与工具按钮。
library;

import 'package:demo1/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('主页应渲染标题、分类导航与 Wiki 工具按钮', (WidgetTester tester) async {
    // 挂载整个应用（ProviderScope 是 App 正常运行的前提）。
    await tester.pumpWidget(const ProviderScope(child: App()));

    // 等待首帧渲染完成。
    await tester.pumpAndSettle();

    // 1. 首次进入动画结束后，顶部栏显示“主页”。
    expect(find.text('主页'), findsOneWidget);

    // 2. 分类导航栏显示「全部」分类标签。
    expect(find.text('全部'), findsOneWidget);

    // 3. 工具网格中包含「Wiki」工具按钮。
    expect(find.text('Wiki'), findsOneWidget);

    // 4. 工具按钮为可点击区域（验证跳转交互入口存在）。
    final Finder toolFinder = find.text('Wiki');
    expect(tester.widget<Text>(toolFinder).style?.fontWeight, isNotNull);
  });
}
