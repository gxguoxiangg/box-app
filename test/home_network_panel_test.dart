/// 主页网络信息面板组件测试。
library;

import 'package:demo1/features/home/view/widgets/home_network_panel.dart';
import 'package:demo1/features/network/data/network_repository.dart';
import 'package:demo1/features/network/models/connection_type.dart';
import 'package:demo1/features/network/models/latency_result.dart';
import 'package:demo1/features/network/models/network_info_data.dart';
import 'package:demo1/features/network/models/network_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _PanelNetworkRepository implements NetworkRepository {
  final ConnectionType type;
  final String? bssid;
  final String? Function()? bssidProvider;

  const _PanelNetworkRepository({
    this.type = ConnectionType.wifi,
    this.bssid,
    this.bssidProvider,
  });

  @override
  Future<NetworkStatus> getConnectionStatus() async =>
      NetworkStatus(type: type);

  @override
  Future<NetworkInfoData> getNetworkDetails() async => NetworkInfoData(
    bssid: bssidProvider?.call() ?? bssid,
    ipv4: '192.168.1.138',
    ipv6: '240e:390:852:1::a7b',
    subnetMask: '255.255.255.0',
    gateway: '192.168.1.1',
  );

  @override
  Future<List<LatencyResult>> testLatencies(List<String> hosts) async =>
      <LatencyResult>[];
}

void main() {
  testWidgets('网络面板展示真实字段，缺失的 MAC 显示占位符', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkRepositoryProvider.overrideWithValue(
            const _PanelNetworkRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HomeNetworkPanel()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('已连接 Wi-Fi'), findsOneWidget);
    expect(find.text('192.168.1.138'), findsOneWidget);
    expect(find.text('255.255.255.0'), findsOneWidget);
    expect(find.text('240e:390:852:1::a7b'), findsOneWidget);
    expect(find.text('192.168.1.1'), findsOneWidget);
    expect(find.text('Wi-Fi 接入点 MAC'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('VPN 下展示接入点 MAC，长按可复制格式化后的内容', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkRepositoryProvider.overrideWithValue(
            const _PanelNetworkRepository(
              type: ConnectionType.vpn,
              bssid: '6a:8f:21:4c:e3:90',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HomeNetworkPanel()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('已连接 VPN'), findsOneWidget);
    expect(find.text('6A8F-214C-E390'), findsOneWidget);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
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
    await tester.tap(find.text('6A8F-214C-E390'));
    await tester.pump();
    expect(copied, isNull);
    await tester.longPress(find.text('6A8F-214C-E390'));
    await tester.pump();
    expect(copied, '6A8F-214C-E390');
  });

  testWidgets('Android 授权后重新读取 VPN 下的接入点地址', (tester) async {
    bool granted = false;
    const MethodChannel channel = MethodChannel('busybox/wifi_access');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall call,
    ) async {
      expect(call.method, 'requestLocationPermission');
      granted = true;
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkRepositoryProvider.overrideWithValue(
            _PanelNetworkRepository(
              type: ConnectionType.vpn,
              bssidProvider: () => granted ? '6a:8f:21:4c:e3:90' : null,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HomeNetworkPanel()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('授权读取接入点 MAC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('6A8F-214C-E390'), findsOneWidget);
  });
}
