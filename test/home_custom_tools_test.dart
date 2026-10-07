/// 常用工具自定义流程与色板回归测试。
library;

import 'package:demo1/app/app.dart';
import 'package:demo1/core/theme/app_theme.dart';
import 'package:demo1/core/theme/busybox_palette.dart';
import 'package:demo1/features/home/viewmodel/home_pinned_viewmodel.dart';
import 'package:demo1/features/home/view/custom_tools_page.dart';
import 'package:demo1/shared/widgets/busybox_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  for (final dark in <bool>[false, true]) {
    testWidgets('320 窄屏${dark ? '深色' : '浅色'}自定义页无溢出且可移除工具', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const CustomToolsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('桌面磁贴个性化配置与快捷挂载'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Wiki')).dy,
        tester.getTopLeft(find.text('神机')).dy,
      );
      final card = find.byType(BusyBoxCard).first;
      final material = tester.widget<Material>(
        find.descendant(of: card, matching: find.byType(Material)).first,
      );
      expect(
        material.color,
        dark ? BusyBoxPalette.dark.canvas : BusyBoxPalette.light.canvas,
      );
      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pumpAndSettle();
      expect(find.text('已选 2/6 项'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('增减常用工具立即生效并保存，且最多六项', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(homePinnedProvider.future), <String>[
      'wiki',
      'speed',
      'smart',
    ]);
    final HomePinnedController controller = container.read(
      homePinnedProvider.notifier,
    );
    await controller.add('prometheus');
    await controller.add('network_calculator');
    await controller.add('hash');
    await controller.add('ping');
    expect(container.read(homePinnedProvider).value?.length, 6);
    await controller.remove('wiki');
    expect(container.read(homePinnedProvider).value, isNot(contains('wiki')));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('home_pinned_tools'), isNot(contains('wiki')));
  });

  testWidgets('点击自定义进入页面，添加后返回主页可见', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义'));
    await tester.pumpAndSettle();
    expect(find.text('自定义常用工具'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(find.text('已选 4/6 项'), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('quick-tool-prometheus')),
      findsOneWidget,
    );
  });

  testWidgets('主页配色扩展随明暗主题切换', (tester) async {
    expect(
      AppTheme.light.extension<BusyBoxPalette>()?.accent,
      BusyBoxPalette.light.accent,
    );
    expect(
      AppTheme.dark.extension<BusyBoxPalette>()?.page,
      BusyBoxPalette.dark.page,
    );
  });

  testWidgets('手机宽度下常用与全部工具均为三列，图标按选中状态着色', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CustomToolsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('工具魔盒 (BusyBox)'), findsNothing);
    final double wikiY = tester.getTopLeft(find.text('Wiki')).dy;
    expect(tester.getTopLeft(find.text('测网速')).dy, wikiY);
    expect(tester.getTopLeft(find.text('神机')).dy, wikiY);
    final double prometheusY = tester.getTopLeft(find.text('普罗米修斯')).dy;
    expect(tester.getTopLeft(find.text('网络计算器')).dy, prometheusY);
    expect(tester.getTopLeft(find.text('Hash')).dy, prometheusY);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.monitor_heart_outlined)).color,
      BusyBoxPalette.light.ink,
    );
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Icon>(find.byIcon(Icons.monitor_heart_outlined)).color,
      BusyBoxPalette.light.accent,
    );
    final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.systemOverlayStyle?.statusBarColor, appBar.backgroundColor);
  });
}
