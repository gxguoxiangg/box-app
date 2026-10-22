import 'package:demo1/features/iadb/models/iadb_models.dart';
import 'package:demo1/features/article/view/widgets/wiki_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo1/features/iadb/view/iadb_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('部门和位置按照需求顺序组合父级名称', () {
    final item = IadbAsset({
      'department_parent': {'name': '研发中心'},
      'department': {'name': '平台组'},
      'location_parent1': {'name': '园区'},
      'location_parent2': {'name': '一号楼'},
      'location': {'name': '三层'},
    });
    expect(item.department, '研发中心 · 平台组');
    expect(item.location, '园区 · 一号楼 · 三层');
  });
  test('缺失和空白层级省略，不添加多余分隔符或去重同名层级', () {
    final item = IadbAsset({
      'department_parent': '   ',
      'department': {'name': '平台组'},
      'location_parent1': {'name': '一区'},
      'location_parent2': null,
      'location': {'name': '一区'},
    });
    expect(item.department, '平台组');
    expect(item.location, '一区 · 一区');
    expect(IadbAsset({}).location, '—');
    expect(IadbAsset({}).department, '—');
  });
  test('时间保留接口钟面时间，去除秒、小数及显示用时区后缀', () {
    for (final raw in [
      '2026-10-18 09:05:59',
      '2026-10-18T09:05:59.123Z',
      '2026-10-18T09:05:59+08:00',
      '2026-10-18 09:05',
    ]) {
      expect(
        IadbAsset({
          'asset': {'created_at': raw},
        }).createdAtLabel,
        '2026-10-18 09:05',
      );
    }
  });
  test('无效日期和空时间使用占位符', () {
    for (final raw in [
      null,
      '',
      'invalid',
      '2026-02-30 09:00:00',
      '2026-10-18 25:00:00',
    ]) {
      expect(
        IadbAsset({
          'asset': {'created_at': raw},
        }).createdAtLabel,
        '—',
      );
    }
  });
  testWidgets('Wiki 顶栏使用统一的粗体标题与副标题字号', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WikiHeader(onBack: () {}, onDirectory: () {}, backLabel: '返回'),
        ),
      ),
    );
    final title = tester.widget<Text>(find.text('Wiki'));
    final subtitle = tester.widget<Text>(find.text('BusyBox · 知识库'));
    expect(title.style?.fontSize, 18);
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(subtitle.style?.fontSize, 12);
  });
  testWidgets('神机使用尖括号返回图标并正常返回上一页', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const IadbPage()),
                ),
                child: const Text('打开神机'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开神机'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('打开神机'), findsOneWidget);
    expect(find.byType(IadbPage), findsNothing);
  });
}
