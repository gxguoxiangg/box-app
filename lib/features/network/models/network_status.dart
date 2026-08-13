/// 当前网络连接状态模型。
///
/// 由 [ConnectionType] 与 Wi-Fi 名称（SSID）组成，
/// 用于页面顶部的连接状态展示。
library;

import 'connection_type.dart';

/// 当前网络连接状态。
class NetworkStatus {
  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 连接类型（Wi-Fi / 移动数据 / 无连接等）。
  final ConnectionType type;

  /// 当前连接的 Wi-Fi 名称（SSID）；非 Wi-Fi 或获取失败时为 null。
  final String? wifiName;

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const NetworkStatus({required this.type, this.wifiName});

  /// 顶部展示的主文案：
  /// - Wi-Fi：显示 Wi-Fi 名称（取不到则显示「Wi-Fi」）；
  /// - 移动数据 / 以太网 / 其他：显示类型名称；
  /// - 无连接：显示「无连接」。
  String get displayLabel {
    switch (type) {
      case ConnectionType.wifi:
        return wifiName?.isNotEmpty == true ? wifiName! : type.label;
      default:
        return type.label;
    }
  }
}
