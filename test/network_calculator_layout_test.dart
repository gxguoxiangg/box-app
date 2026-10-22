import 'dart:io';
import 'dart:ui' as ui;

import 'package:demo1/core/theme/app_theme.dart';
import 'package:demo1/features/network_calculator/view/network_calculator_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0, 800.0]) {
      testWidgets('Oct-22 计算器布局 width=$width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fontPath = Platform.environment['BUSYBOX_PREVIEW_FONT'];
        if (fontPath != null) {
          await tester.runAsync(() async {
            final loader = FontLoader(
              'PreviewChinese',
            )..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
            await loader.load();
            final icons = Platform.environment['BUSYBOX_PREVIEW_ICONS'];
            if (icons != null) {
              await (FontLoader('MaterialIcons')..addFont(
                    File(icons).readAsBytes().then(ByteData.sublistView),
                  ))
                  .load();
            }
          });
        }
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: (dark ? AppTheme.dark : AppTheme.light).copyWith(
                textTheme: (dark ? AppTheme.dark : AppTheme.light).textTheme
                    .apply(
                      fontFamily: fontPath == null ? null : 'PreviewChinese',
                    ),
              ),
              home: RepaintBoundary(
                key: boundary,
                child: const NetworkCalculatorPage(),
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(width == 320 ? 2 : 1)),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('网络号 (Network)'), findsOneWidget);
        expect(find.text('广播号 (Broadcast)'), findsOneWidget);
        expect(find.text('255.255.255.0'), findsOneWidget);
        expect(find.text('256 个 IP'), findsOneWidget);
        final network = tester.getTopLeft(find.text('网络号 (Network)'));
        final broadcast = tester.getTopLeft(find.text('广播号 (Broadcast)'));
        if (width >= 390) {
          expect(network.dy, broadcast.dy);
          expect(network.dx, lessThan(broadcast.dx));
        } else {
          expect(network.dy, lessThan(broadcast.dy));
        }
        await tester.ensureVisible(find.text('192.168.10.1 ~ 192.168.10.254'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // 可选截图只在本地显式指定字体时生成，普通测试不依赖机器字体。
        if (fontPath != null && width == 390) {
          await tester.ensureVisible(find.text('子网掩码计算'));
          for (final scroll in tester.stateList<ScrollableState>(
            find.byType(Scrollable),
          )) {
            scroll.position.jumpTo(0);
          }
          await tester.pumpAndSettle();
          final render = boundary.currentContext?.findRenderObject();
          if (render is RenderRepaintBoundary) {
            await tester.runAsync(() async {
              final snapshot = await render.toImage(pixelRatio: 2);
              final bytes = await snapshot.toByteData(
                format: ui.ImageByteFormat.png,
              );
              if (bytes != null) {
                await Directory(
                  'build/network_calculator_preview',
                ).create(recursive: true);
                await File(
                  'build/network_calculator_preview/${dark ? 'dark' : 'light'}.png',
                ).writeAsBytes(bytes.buffer.asUint8List());
              }
              snapshot.dispose();
            });
          }
        }
      });
    }
  }
}
