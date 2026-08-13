/// 网络信息模块 ViewModel（MVVM 的 VM 层）。
///
/// 聚合三类数据到 [NetworkData]：
/// 1. 连接状态（类型 + Wi-Fi 名称）；
/// 2. 设备网络详情（IP / 网关等）；
/// 3. 指定网站的延迟测试结果。
///
/// View 通过 `ref.watch(networkViewModelProvider)` 订阅，三态（加载/错误/数据）
/// 由 `AsyncValue` 承载。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/network_repository.dart';
import '../models/latency_result.dart';
import '../models/network_info_data.dart';
import '../models/network_status.dart';

/// 网络模块聚合数据。
class NetworkData {
  /// 连接状态。
  final NetworkStatus status;

  /// 设备网络详情。
  final NetworkInfoData info;

  /// 延迟测试结果列表。
  final List<LatencyResult> latencies;

  const NetworkData({
    required this.status,
    required this.info,
    required this.latencies,
  });
}

/// 网络信息 ViewModel。
class NetworkViewModel extends AsyncNotifier<NetworkData> {
  /// 延迟测试的目标主机（当前使用仓库默认列表）。
  static const List<String> testHosts =
      ConnectivityNetworkRepository.defaultTestHosts;

  @override
  Future<NetworkData> build() => _load();

  /// 加载全部网络数据（首次进入页面时自动调用）。
  Future<NetworkData> _load() async {
    final NetworkRepository repository = ref.read(networkRepositoryProvider);

    // 并发发起三项请求（先启动再等待，缩短整体耗时）。
    final Future<NetworkStatus> statusFuture = repository.getConnectionStatus();
    final Future<NetworkInfoData> infoFuture = repository.getNetworkDetails();
    final Future<List<LatencyResult>> latencyFuture =
        repository.testLatencies(testHosts);

    final NetworkStatus status = await statusFuture;
    final NetworkInfoData info = await infoFuture;
    final List<LatencyResult> latencies = await latencyFuture;

    return NetworkData(status: status, info: info, latencies: latencies);
  }

  /// 手动刷新（下拉刷新 / 错误重试时调用）。
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}

/// 网络信息 ViewModel Provider。
final networkViewModelProvider =
    AsyncNotifierProvider<NetworkViewModel, NetworkData>(NetworkViewModel.new);
