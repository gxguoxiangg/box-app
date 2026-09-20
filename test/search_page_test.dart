/// 功能搜索页测试。
///
/// 验证搜索页自动匹配功能名称、空结果提示和搜索入口的渲染。
library;

import 'package:demo1/features/home/view/search_page.dart';
import 'package:demo1/features/home/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('输入字符后应立即按连续文本匹配功能模块', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProviderScope(child: SearchPage())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Wiki');
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('网络信息'), findsNothing);
  });

  testWidgets('没有匹配结果时应显示空', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProviderScope(child: SearchPage())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '不存在的功能');
    await tester.pump();

    expect(find.text('空'), findsOneWidget);
  });

  testWidgets('搜索页销毁后重新进入应显示完整列表且输入框为空', (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SearchPage()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Wiki');
    await tester.pump();
    expect(container.read(toolSearchControllerProvider), 'Wiki');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    expect(container.read(toolSearchControllerProvider), isEmpty);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SearchPage()),
      ),
    );
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('网络信息'), findsOneWidget);
  });
}
