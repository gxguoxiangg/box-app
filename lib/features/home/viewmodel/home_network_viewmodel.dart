/// 主页网络摘要：只加载连接状态和地址信息，不启动网站延迟测试。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/data/network_repository.dart';
import '../../network/models/connection_type.dart';
import '../../network/models/network_info_data.dart';
import '../../network/models/network_status.dart';

/// 主页网络信息面板需要的数据。
class HomeNetworkSnapshot {
  /// 当前连接状态。
  final NetworkStatus status;

  /// 当前设备网络地址。
  final NetworkInfoData info;

  /// 创建一份网络摘要。
  const HomeNetworkSnapshot({required this.status, required this.info});

  /// 右上角的连接状态文案。
  String get badgeLabel => switch (status.type) {
    ConnectionType.wifi => '已连接 Wi-Fi',
    ConnectionType.mobile => '移动数据',
    ConnectionType.vpn => '已连接 VPN',
    ConnectionType.none => '无连接',
    _ => status.type.label,
  };
}

/// 主页网络摘要 Provider；离开主页后释放，再次进入时重新读取。
final homeNetworkSnapshotProvider =
    FutureProvider.autoDispose<HomeNetworkSnapshot>((ref) async {
      ref.watch(_connectionChangesProvider);
      final NetworkRepository repository = ref.watch(networkRepositoryProvider);
      // 两项读取互不依赖，任一插件失败时该字段使用空值，保留另一项的结果。
      final Future<NetworkStatus> statusFuture = repository
          .getConnectionStatus()
          .catchError(
            (Object _) => const NetworkStatus(type: ConnectionType.none),
          );
      final Future<NetworkInfoData> infoFuture = repository
          .getNetworkDetails()
          .catchError((Object _) => const NetworkInfoData());
      return HomeNetworkSnapshot(
        status: await statusFuture,
        info: await infoFuture,
      );
    });

// 自动释放插件订阅；平台不支持通知时仍可正常读取一次摘要。
final _connectionChangesProvider = StreamProvider.autoDispose<void>((ref) {
  final NetworkRepository repository = ref.watch(networkRepositoryProvider);
  return repository is NetworkConnectionEvents
      ? (repository as NetworkConnectionEvents).connectionChanges
      : const Stream<void>.empty();
});

/// 后期扩展：连接变更只刷新摘要，互联网可达性或速率必须独立实测。
