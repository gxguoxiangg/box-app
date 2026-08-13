/// 全局设置页组件测试。
///
/// 验证「深色模式」开关：点击后可切换主题模式。
library;

import 'package:demo1/core/theme/theme_controller.dart';
import 'package:demo1/features/settings/view/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('深色模式开关可切换主题', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 初始为明亮模式：开关关闭。
    final Finder switchFinder = find.byType(SwitchListTile);
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

    // 点击开关，切换为深色模式。
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

    // 验证主题控制器状态已切换。
    final ProviderContainer container =
        ProviderScope.containerOf(tester.element(find.byType(SettingsPage)));
    expect(container.read(themeControllerProvider).value, ThemeMode.dark);

    // 再次点击，切回明亮模式。
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
    expect(container.read(themeControllerProvider).value, ThemeMode.light);
  });
}
