import 'package:demo1/core/theme/app_theme.dart';
import 'package:demo1/features/network_calculator/view/network_calculator_page.dart';
import 'package:demo1/features/home/data/home_tool_options.dart';
import 'package:demo1/features/home/data/tool_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('主页目录和搜索均接入计算器', () {
    expect(
      homeToolOptions
          .singleWhere((v) => v.id == 'network_calculator')
          .routePath,
      AppRoutes.networkCalculator,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container
          .read(toolRegistryProvider)
          .singleWhere((v) => v.id == 'network_calculator')
          .routePath,
      AppRoutes.networkCalculator,
    );
  });
  for (final dark in [false, true]) {
    testWidgets('320px 计算器实时输入、复制和未开放提示 dark=$dark', (tester) async {
      tester.view.physicalSize = const Size(320, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
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
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const NetworkCalculatorPage(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.text('网络计算器')).style?.fontSize, 18);
      expect(
        tester.widget<Text>(find.text('网络计算器')).style?.fontWeight,
        FontWeight.w700,
      );
      expect(tester.widget<Text>(find.text('BusyBox')).style?.fontSize, 12);
      expect(
        tester.widget<Text>(find.text('BusyBox')).style?.fontWeight,
        FontWeight.w700,
      );
      expect(find.byKey(const ValueKey('subnet-cidr-badge')), findsOneWidget);
      expect(find.text('192.168.10.1 ~ 192.168.10.254'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('subnet-octet-2')),
        '20',
      );
      await tester.pump();
      expect(find.text('192.168.20.1 ~ 192.168.20.254'), findsOneWidget);
      await tester.tap(find.byTooltip('增加前缀长度'));
      await tester.pumpAndSettle();
      expect(find.text('255.255.255.128'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('复制子网掩码 (Subnet Mask)'));
      await tester.tap(find.byTooltip('复制子网掩码 (Subnet Mask)'));
      await tester.pumpAndSettle();
      expect(clipboard, '255.255.255.128');
      await tester.ensureVisible(find.byKey(const ValueKey('subnet-octet-0')));
      await tester.enterText(
        find.byKey(const ValueKey('subnet-octet-0')),
        '999',
      );
      await tester.pump();
      expect(find.text('请输入有效地址后查看计算结果'), findsOneWidget);
      expect(find.text('255.255.255.128'), findsNothing);
      await tester.ensureVisible(find.text('POE计算'));
      await tester.tap(find.text('POE计算'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('暂未开放'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
