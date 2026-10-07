/// 网络连接类型。
///
/// 将 `connectivity_plus` 的 [ConnectivityResult] 归一化为界面友好的
/// 展示类型（含名称与图标），便于后期新增类型时集中维护。
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// 连接类型（界面展示用）。
enum ConnectionType {
  /// Wi-Fi。
  wifi(label: 'Wi-Fi', icon: Icons.wifi_rounded),

  /// 移动数据（蜂窝网络）。
  mobile(label: '移动数据', icon: Icons.network_cell_rounded),

  /// 虚拟专用网络。
  vpn(label: 'VPN', icon: Icons.vpn_lock_rounded),

  /// 以太网（有线网络）。
  ethernet(label: '以太网', icon: Icons.lan_rounded),

  /// 蓝牙网络。
  bluetooth(label: '蓝牙', icon: Icons.bluetooth_rounded),

  /// 无任何连接。
  none(label: '无连接', icon: Icons.wifi_off_rounded),

  /// 其他未知网络类型。
  other(label: '其他网络', icon: Icons.network_ping_rounded);

  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 显示名称。
  final String label;

  /// 展示图标。
  final IconData icon;

  const ConnectionType({required this.label, required this.icon});

  // ---------------------------------------------------------------------------
  // 映射
  // ---------------------------------------------------------------------------

  /// 将 connectivity_plus 返回的结果列表映射为唯一连接类型。
  ///
  /// VPN 可以与 Wi-Fi / 移动数据同时出现，优先标识 VPN；其余结果按顺序选
  /// 第一个已知连接类型，全部为 none 时视为无连接。
  static ConnectionType fromConnectivityResults(
    List<ConnectivityResult> results,
  ) {
    if (results.contains(ConnectivityResult.vpn)) return ConnectionType.vpn;
    for (final ConnectivityResult result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          return ConnectionType.wifi;
        case ConnectivityResult.mobile:
          return ConnectionType.mobile;
        case ConnectivityResult.vpn:
          return ConnectionType.vpn;
        case ConnectivityResult.ethernet:
          return ConnectionType.ethernet;
        case ConnectivityResult.bluetooth:
          return ConnectionType.bluetooth;
        case ConnectivityResult.none:
          // 继续检查其他结果。
          continue;
        default:
          // satellite / other 等归为「其他网络」。
          return ConnectionType.other;
      }
    }
    return ConnectionType.none;
  }
}
