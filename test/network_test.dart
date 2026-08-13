/// 网络信息模块测试。
///
/// 覆盖：
/// 1. 模型层：连接类型映射、状态文案、延迟展示文案；
/// 2. ViewModel：通过 Mock 仓库加载聚合数据；
/// 3. View：网络信息页渲染（连接状态卡片 / 设备信息 / 延迟网格 / 操作栏）。
library;

import 'package:demo1/features/network/data/network_repository.dart';
import 'package:demo1/features/network/models/connection_type.dart';
import 'package:demo1/features/network/models/latency_result.dart';
import 'package:demo1/features/network/models/network_info_data.dart';
import 'package:demo1/features/network/models/network_status.dart';
import 'package:demo1/features/network/view/network_page.dart';
import 'package:demo1/features/network/viewmodel/network_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ---------------------------------------------------------------------------
// 测试用 Mock 仓库
// ---------------------------------------------------------------------------

/// 返回固定数据的假仓库（避免依赖真实插件与网络）。
class FakeNetworkRepository implements NetworkRepository {
  @override
  Future<NetworkStatus> getConnectionStatus() async {
    return const NetworkStatus(type: ConnectionType.wifi, wifiName: 'HomeWiFi');
  }

  @override
  Future<NetworkInfoData> getNetworkDetails() async {
    return const NetworkInfoData(
      ipv4: '192.168.1.100',
      gateway: '192.168.1.1',
      ssid: 'HomeWiFi',
    );
  }

  @override
  Future<List<LatencyResult>> testLatencies(List<String> hosts) async {
    return <LatencyResult>[
      for (final String host in hosts)
        LatencyResult(
          host: host,
          url: 'https://$host/',
          success: true,
          latencyMs: 42,
          testedAt: DateTime(2026, 1, 1),
        ),
    ];
  }
}

void main() {
  // -------------------------------------------------------------------------
  // 模型层单元测试
  // -------------------------------------------------------------------------
  group('ConnectionType.fromConnectivityResults', () {
    test('Wi-Fi 结果映射为 wifi', () {
      expect(
        ConnectionType.fromConnectivityResults(<ConnectivityResult>[ConnectivityResult.wifi]),
        ConnectionType.wifi,
      );
    });

    test('移动数据结果映射为 mobile', () {
      expect(
        ConnectionType.fromConnectivityResults(<ConnectivityResult>[ConnectivityResult.mobile]),
        ConnectionType.mobile,
      );
    });

    test('无连接（none）映射为 none', () {
      expect(
        ConnectionType.fromConnectivityResults(<ConnectivityResult>[ConnectivityResult.none]),
        ConnectionType.none,
      );
    });

    test('空列表映射为 none', () {
      expect(ConnectionType.fromConnectivityResults(const <ConnectivityResult>[]),
          ConnectionType.none);
    });
  });

  group('NetworkStatus.displayLabel', () {
    test('Wi-Fi 时显示名称', () {
      const NetworkStatus status =
          NetworkStatus(type: ConnectionType.wifi, wifiName: 'MyWiFi');
      expect(status.displayLabel, 'MyWiFi');
    });

    test('Wi-Fi 但名称为空时显示类型名', () {
      const NetworkStatus status = NetworkStatus(type: ConnectionType.wifi);
      expect(status.displayLabel, 'Wi-Fi');
    });

    test('移动数据时显示「移动数据」', () {
      const NetworkStatus status = NetworkStatus(type: ConnectionType.mobile);
      expect(status.displayLabel, '移动数据');
    });

    test('无连接时显示「无连接」', () {
      const NetworkStatus status = NetworkStatus(type: ConnectionType.none);
      expect(status.displayLabel, '无连接');
    });
  });

  group('LatencyResult', () {
    test('成功时显示延迟毫秒', () {
      final LatencyResult result = LatencyResult(
        host: 'www.baidu.com',
        url: 'https://www.baidu.com/',
        success: true,
        latencyMs: 88,
        testedAt: DateTime(2026, 1, 1),
      );
      expect(result.displayText, '88 ms');
    });

    test('失败时显示不可达', () {
      final LatencyResult result = LatencyResult(
        host: 'www.baidu.com',
        url: 'https://www.baidu.com/',
        success: false,
        testedAt: DateTime(2026, 1, 1),
      );
      expect(result.displayText, '不可达');
    });
  });

  // -------------------------------------------------------------------------
  // ViewModel 测试
  // -------------------------------------------------------------------------
  test('ViewModel 通过仓库加载聚合数据', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        networkRepositoryProvider.overrideWithValue(FakeNetworkRepository()),
      ],
    );
    addTearDown(container.dispose);

    final NetworkData data =
        await container.read(networkViewModelProvider.future);

    expect(data.status.type, ConnectionType.wifi);
    expect(data.status.wifiName, 'HomeWiFi');
    expect(data.info.ipv4, '192.168.1.100');
    // 延迟测试结果与默认主机数量一致。
    expect(data.latencies.length, NetworkViewModel.testHosts.length);
    expect(data.latencies.first.latencyMs, 42);
  });

  // -------------------------------------------------------------------------
  // View 组件测试
  // -------------------------------------------------------------------------
  testWidgets('网络信息页渲染连接状态、设备信息、延迟网格与操作栏',
      (WidgetTester tester) async {
    // 加大测试视口，确保 ListView 底部操作栏也在渲染范围内。
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkRepositoryProvider.overrideWithValue(FakeNetworkRepository()),
        ],
        child: const MaterialApp(home: NetworkPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 标题与连接状态卡片（Wi-Fi 名称；顶部状态卡与设备信息卡各出现一次）。
    expect(find.text('网络信息'), findsOneWidget);
    expect(find.text('HomeWiFi'), findsWidgets);

    // 2. 设备信息：IP 地址与网关。
    expect(find.text('192.168.1.100'), findsOneWidget);
    expect(find.text('192.168.1.1'), findsOneWidget);

    // 3. 延迟网格：结果文案出现（每个主机一张卡片）。
    expect(find.text('42 ms'), findsWidgets);
    expect(find.byType(GridView), findsWidgets);

    // 4. 底部操作栏按钮。
    expect(find.text('测试网速'), findsOneWidget);
    expect(find.text('更多工具'), findsOneWidget);
  });
}
