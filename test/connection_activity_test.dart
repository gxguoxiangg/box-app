import 'package:demo1/features/home/view/widgets/connection_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget build({
    required bool connected,
    bool reduced = false,
    bool visible = true,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: TickerMode(
        enabled: visible,
        child: ConnectionActivity(connected: connected),
      ),
    ),
  );

  List<double> heights(WidgetTester tester) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(ConnectionActivity),
          matching: find.byType(Container),
        ),
      )
      .map((bar) => bar.constraints!.maxHeight)
      .toList();

  testWidgets('连接时播放，断开后停止，不提供流量读数', (tester) async {
    await tester.pumpWidget(build(connected: true));
    final List<double> first = heights(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(heights(tester), isNot(first));
    expect(find.byTooltip('连接状态动效，非实时流量'), findsOneWidget);
    await tester.pumpWidget(build(connected: false));
    expect(heights(tester), <double>[4, 4, 4]);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('减少动画或路由不可见时停播，恢复后继续', (tester) async {
    await tester.pumpWidget(build(connected: true, reduced: true));
    final List<double> still = heights(tester);
    await tester.pumpAndSettle();
    expect(heights(tester), still);
    await tester.pumpWidget(build(connected: true, visible: false));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(build(connected: true));
    await tester.pump(const Duration(milliseconds: 200));
    expect(heights(tester), isNot(still));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
