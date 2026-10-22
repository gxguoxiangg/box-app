import 'package:demo1/core/theme/app_theme.dart';
import 'package:demo1/features/network_calculator/view/network_calculator_page.dart';
import 'package:demo1/features/network_calculator/viewmodel/subnet_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('计算结果同行与主机基线 width=$width scale=$scale', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const NetworkCalculatorPage(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
        for (final prefix in [32, 1]) {
          container.read(subnetProvider.notifier).setPrefix(prefix);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getCenter(find.text('计算结果')).dy,
            closeTo(tester.getCenter(find.text('IPv4 标准')).dy, 0.1),
          );
          expect(
            tester.getTopLeft(find.text('可用主机数量 (Hosts)')).dy,
            closeTo(tester.getTopLeft(find.text('总分配空间')).dy, 0.1),
          );
          double baseline(String key) {
            final finder = find.byKey(ValueKey(key));
            final paragraph = tester.renderObject<RenderParagraph>(finder);
            return tester.getTopLeft(finder).dy +
                (paragraph.getDryBaseline(
                      paragraph.constraints,
                      TextBaseline.alphabetic,
                    ) ??
                    0);
          }

          expect(
            baseline('subnet-usable-count'),
            closeTo(baseline('subnet-total-count'), 0.1),
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('subnet-total-count')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
