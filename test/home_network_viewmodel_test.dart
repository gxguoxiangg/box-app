/// 主页网络摘要测试；不依赖设备插件或真实网络。
library;

import 'dart:async';

import 'package:demo1/features/home/viewmodel/home_network_viewmodel.dart';
import 'package:demo1/features/network/data/network_repository.dart';
import 'package:demo1/features/network/models/connection_type.dart';
import 'package:demo1/features/network/models/latency_result.dart';
import 'package:demo1/features/network/models/network_info_data.dart';
import 'package:demo1/features/network/models/network_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNetworkRepository implements NetworkRepository {
  bool latencyTestCalled = false;

  @override
  Future<NetworkStatus> getConnectionStatus() async =>
      const NetworkStatus(type: ConnectionType.wifi, wifiName: 'Office');

  @override
  Future<NetworkInfoData> getNetworkDetails() async =>
      const NetworkInfoData(ipv4: '192.168.1.20', subnetMask: '255.255.255.0');

  @override
  Future<List<LatencyResult>> testLatencies(List<String> hosts) async {
    latencyTestCalled = true;
    return <LatencyResult>[];
  }
}

void main() {
  test('连接变更会刷新摘要，销毁容器后释放订阅', () async {
    final repository = _ChangingNetworkRepository();
    final container = ProviderContainer(
      overrides: [networkRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(
      homeNetworkSnapshotProvider,
      (_, _) {},
    );
    expect(
      (await container.read(homeNetworkSnapshotProvider.future)).status.type,
      ConnectionType.wifi,
    );
    repository.type = ConnectionType.none;
    repository.events.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(
      (await container.read(homeNetworkSnapshotProvider.future)).status.type,
      ConnectionType.none,
    );
    subscription.close();
    container.dispose();
    expect(repository.events.hasListener, isFalse);
    await repository.events.close();
  });
  test('主页只读取状态与地址，不发起延迟测试', () async {
    final _FakeNetworkRepository repository = _FakeNetworkRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [networkRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final HomeNetworkSnapshot snapshot = await container.read(
      homeNetworkSnapshotProvider.future,
    );
    expect(snapshot.badgeLabel, '已连接 Wi-Fi');
    expect(snapshot.info.ipv4, '192.168.1.20');
    expect(repository.latencyTestCalled, isFalse);
  });

  test('连接状态文案覆盖移动数据、VPN 和无连接', () {
    const NetworkInfoData emptyInfo = NetworkInfoData();
    expect(
      const HomeNetworkSnapshot(
        status: NetworkStatus(type: ConnectionType.mobile),
        info: emptyInfo,
      ).badgeLabel,
      '移动数据',
    );
    expect(
      const HomeNetworkSnapshot(
        status: NetworkStatus(type: ConnectionType.vpn),
        info: emptyInfo,
      ).badgeLabel,
      '已连接 VPN',
    );
    expect(
      const HomeNetworkSnapshot(
        status: NetworkStatus(type: ConnectionType.none),
        info: emptyInfo,
      ).badgeLabel,
      '无连接',
    );
  });
}

class _ChangingNetworkRepository extends _FakeNetworkRepository
    implements NetworkConnectionEvents {
  final events = StreamController<void>.broadcast();
  ConnectionType type = ConnectionType.wifi;

  @override
  Stream<void> get connectionChanges => events.stream;

  @override
  Future<NetworkStatus> getConnectionStatus() async =>
      NetworkStatus(type: type);
}
