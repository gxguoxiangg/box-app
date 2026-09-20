/// 网络信息数据仓库（Repository）。
///
/// MVVM 数据层，屏蔽「数据从哪里来」的细节：
/// - 连接类型来自 `connectivity_plus`；
/// - IP / Wi-Fi 详情来自 `network_info_plus`；
/// - 网站延迟通过 `http` 请求实测。
///
/// 定义为抽象接口 + 真实实现，便于单元测试时注入 Mock（见 test/）。
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

import '../models/connection_type.dart';
import '../models/latency_result.dart';
import '../models/network_info_data.dart';
import '../models/network_status.dart';

/// 仓库抽象接口（供 ViewModel 依赖，测试时可替换为 Mock）。
abstract class NetworkRepository {
  /// 获取当前连接状态（类型 + Wi-Fi 名称）。
  Future<NetworkStatus> getConnectionStatus();

  /// 获取设备网络详情（IP、网关等）。
  Future<NetworkInfoData> getNetworkDetails();

  /// 对指定主机列表逐一进行延迟测试，返回结果列表。
  Future<List<LatencyResult>> testLatencies(List<String> hosts);
}

/// 基于真实插件的仓库实现。
class ConnectivityNetworkRepository implements NetworkRepository {
  /// 默认延迟测试目标（可后期扩展/远程下发）。
  static const List<String> defaultTestHosts = <String>[
    'www.baidu.com',
    'www.qq.com',
    'www.taobao.com',
    'github.com',
    'www.bing.com',
    'www.google.com',
  ];

  /// 单次请求超时时间（毫秒）。
  static const Duration latencyTimeout = Duration(seconds: 5);

  final Connectivity _connectivity;
  final NetworkInfo _networkInfo;
  final http.Client _http;
  final bool _ownsHttpClient;

  /// 释放本仓库创建的网络客户端。
  void dispose() {
    if (_ownsHttpClient) _http.close();
  }

  /// 可注入依赖（测试时传入 Mock 的插件/客户端）。
  ConnectivityNetworkRepository({
    Connectivity? connectivity,
    NetworkInfo? networkInfo,
    http.Client? httpClient,
  }) : _connectivity = connectivity ?? Connectivity(),
       _networkInfo = networkInfo ?? NetworkInfo(),
       _http = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  @override
  Future<NetworkStatus> getConnectionStatus() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    final ConnectionType type = ConnectionType.fromConnectivityResults(results);

    // 仅 Wi-Fi 时尝试获取 SSID；非 Wi-Fi 场景无需请求。
    String? wifiName;
    if (type == ConnectionType.wifi) {
      wifiName = await _safeString(_networkInfo.getWifiName);
    }

    return NetworkStatus(type: type, wifiName: wifiName);
  }

  @override
  Future<NetworkInfoData> getNetworkDetails() async {
    // 逐项安全获取：任何一项失败都不影响整体返回。
    return NetworkInfoData(
      ssid: await _safeString(_networkInfo.getWifiName),
      bssid: await _safeString(_networkInfo.getWifiBSSID),
      ipv4: await _safeString(_networkInfo.getWifiIP),
      ipv6: await _safeString(_networkInfo.getWifiIPv6),
      subnetMask: await _safeString(_networkInfo.getWifiSubmask),
      gateway: await _safeString(_networkInfo.getWifiGatewayIP),
      broadcast: await _safeString(_networkInfo.getWifiBroadcast),
      // 预留字段（现代平台大多无法直接获取，保持 null 展示「—」）。
      macAddress: null,
      linkSpeedMbps: null,
      channel: null,
      band: null,
    );
  }

  @override
  Future<List<LatencyResult>> testLatencies(List<String> hosts) async {
    // 并发测试，缩短整体等待时间。
    final List<Future<LatencyResult>> futures = hosts
        .map(_testLatency)
        .toList();
    return Future.wait(futures);
  }

  /// 对单个主机进行延迟测试。
  Future<LatencyResult> _testLatency(String host) async {
    final String url = 'https://$host/';
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      await _http.get(Uri.parse(url)).timeout(latencyTimeout);
      stopwatch.stop();
      return LatencyResult(
        host: host,
        url: url,
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        testedAt: DateTime.now(),
      );
    } catch (_) {
      // 超时 / 网络错误 / 跨域限制等均视为不可达。
      stopwatch.stop();
      return LatencyResult(
        host: host,
        url: url,
        success: false,
        testedAt: DateTime.now(),
      );
    }
  }

  /// 安全执行返回 String? 的插件调用，异常时返回 null。
  Future<String?> _safeString(Future<String?> Function() call) async {
    try {
      return await call();
    } catch (_) {
      return null;
    }
  }
}

/// 网络仓库 Provider（真实实现）。
///
/// 测试时通过 `overrideWithValue` 替换为 Mock 实现。
final networkRepositoryProvider = Provider<NetworkRepository>((ref) {
  final ConnectivityNetworkRepository repository =
      ConnectivityNetworkRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
