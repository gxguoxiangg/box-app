import 'dart:io';
import 'dart:ui' as ui;
import 'package:demo1/features/iadb/models/iadb_models.dart';
import 'package:demo1/features/iadb/view/iadb_asset_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('厂商和权限缺失时不使用描述或英文猜测字段替代', (tester) async {
    for (final empty in [null, '', '   ']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IadbAssetCard(
              asset: IadbAsset({
                'asset': {
                  'id': 1,
                  'name': '原名称',
                  'description': '原描述',
                  'vendor': empty,
                  'model': empty,
                  '权限类别': empty,
                  'permission': '不得猜测',
                },
              }),
              onDetails: () {},
              onCopy: (_, _) {},
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('iadb-vendor-title')))
            .data,
        '—',
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('iadb-permission-label')),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );
      expect(find.text('原名称'), findsNothing);
      expect(find.byKey(const ValueKey('iadb-model-label')), findsNothing);
      expect(find.text('不得猜测'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
  for (final dark in [false, true]) {
    testWidgets('资产卡片多网卡、长文本及放大字体 ${dark ? '深色' : '浅色'}', (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = Platform.environment['IADB_PREVIEW_FONT'];
      if (font != null) {
        await tester.runAsync(() async {
          final loader = FontLoader('PreviewChinese')
            ..addFont(
              File(
                font,
              ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            );
          await loader.load();
          // 可选真实字体仅用于本地截图；普通回归测试不依赖机器字体路径。
          for (final entry in {
            'monospace': Platform.environment['IADB_PREVIEW_MONO_FONT'],
            'MaterialIcons': Platform.environment['IADB_PREVIEW_ICON_FONT'],
          }.entries) {
            final path = entry.value;
            if (path == null) continue;
            final extra = FontLoader(entry.key)
              ..addFont(File(path).readAsBytes().then(ByteData.sublistView));
            await extra.load();
          }
        });
      }
      final item = IadbAsset({
        'asset': {
          'id': 7,
          'name': '台式机',
          'vendor': '测试厂商',
          '权限类别': '仅绑定',
          'asset_type': '工作站',
          'description': '资产用途说明',
          'model': 'Workstation 2026',
          'status': 'online',
          'asset_code': 'AST-2026-0007',
          'created_at': '2026-10-15 10:30:00',
        },
        'owner': {'name': '测试负责人'},
        'department_parent': {'name': '研发中心'},
        'location_parent1': {'name': '园区'},
        'location_parent2': {'name': '一号楼'},
        'department': {'name': '基础设施与系统运维部门'},
        'location': {'name': '测试园区 · 一号楼 · 综合办公区'},
        'interfaces': [
          {
            'interface_name': 'Ethernet',
            'mac_address': 'AA:BB:CC:DD:EE:01',
            'ip_addresses': [
              {'ip_address': '192.0.2.10', 'allocation_type': 'static'},
            ],
          },
          {
            'interface_name': 'Wi-Fi',
            'mac_address': 'AA:BB:CC:DD:EE:02',
            'ip_addresses': [
              {'ip_address': '2001:db8:1234:5678:abcd:ef01:2345:6789'},
            ],
          },
        ],
      });
      String? copied;
      var details = false;
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
            fontFamily: font == null ? null : 'PreviewChinese',
          ),
          home: RepaintBoundary(
            key: boundaryKey,
            child: Scaffold(
              body: SafeArea(
                child: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      IadbAssetCard(
                        asset: item,
                        onDetails: () => details = true,
                        onCopy: (_, value) => copied = value,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ethernet'), findsOneWidget);
      expect(find.text('工作站'), findsOneWidget);
      expect(find.text('研发中心 · 基础设施与系统运维部门'), findsOneWidget);
      expect(find.text('园区 · 一号楼 · 测试园区 · 一号楼 · 综合办公区'), findsOneWidget);
      expect(find.text('资产用途说明'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('iadb-permission-label')),
          matching: find.text('仅绑定'),
        ),
        findsOneWidget,
      );
      expect(find.text('测试厂商'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('iadb-vendor-title')))
            .data,
        '测试厂商',
      );
      expect(find.text('台式机', findRichText: true), findsNothing);
      expect(
        find.textContaining('Workstation', findRichText: true),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('iadb-vendor-title')))
            .style
            ?.fontSize,
        18,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('iadb-model-label')))
            .style
            ?.fontSize,
        16,
      );
      expect(find.text('AST-2026-0007'), findsNothing);
      expect(find.text('2026-10-15 10:30'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('资产用途说明')).dy,
        lessThan(tester.getTopLeft(find.text('测试厂商')).dy),
      );
      expect(find.text('Wi-Fi'), findsOneWidget);
      await tester.tap(find.text('AA:BB:CC:DD:EE:02'));
      expect(copied, 'AA:BB:CC:DD:EE:02');
      await tester.ensureVisible(find.text('详情'));
      await tester.tap(find.text('详情'));
      expect(details, isTrue);
      await tester.pumpAndSettle();
      if (font != null) {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/iadb_ui_preview').create(recursive: true);
          await File(
            'build/iadb_ui_preview/${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
