/// 网络详细信息模型。
///
/// 存储设备在当前网络下的 IP、网关、DNS 等基础信息。
/// 依赖 `network_info_plus`，部分字段在当前平台不可用时为 null。
///
/// 扩展说明：后期若需展示「信道、协商速率、频段」等更深层 Wi-Fi 信息，
/// 需接入平台原生 API（如 Android `WifiManager`），在模型中追加字段即可。
library;

/// 网络详细信息。
class NetworkInfoData {
  // ---------------------------------------------------------------------------
  // 字段（均可为 null：平台不支持 / 未连接 / 获取失败时兜底展示「—」）
  // ---------------------------------------------------------------------------

  /// Wi-Fi 名称（SSID）。
  final String? ssid;

  /// Wi-Fi BSSID（路由器 MAC 地址）。
  final String? bssid;

  /// 当前 Wi-Fi 接入点的 MAC，格式为 XXXX-XXXX-XXXX。
  ///
  /// BSSID 是路由器接入点地址，不是本机网卡 MAC；VPN 建立时仍可来自底层 Wi-Fi。
  String? get accessPointMac => formatAccessPointMac(bssid);

  /// IPv4 地址。
  final String? ipv4;

  /// IPv6 地址。
  final String? ipv6;

  /// 子网掩码。
  final String? subnetMask;

  /// 网关地址。
  final String? gateway;

  /// 广播地址。
  final String? broadcast;

  /// 设备 MAC 地址（预留：现代系统普遍无法获取真实 MAC，暂为 null）。
  final String? macAddress;

  /// 协商速率（Mbps，预留：需平台原生支持）。
  final int? linkSpeedMbps;

  /// Wi-Fi 信道（预留）。
  final int? channel;

  /// 频段（预留：如 2.4GHz / 5GHz）。
  final String? band;

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const NetworkInfoData({
    this.ssid,
    this.bssid,
    this.ipv4,
    this.ipv6,
    this.subnetMask,
    this.gateway,
    this.broadcast,
    this.macAddress,
    this.linkSpeedMbps,
    this.channel,
    this.band,
  });
}

/// 规范化接入点 BSSID；过滤系统脱敏值和无效地址。
String? formatAccessPointMac(String? raw) {
  if (raw == null) return null;
  final String hex = raw.replaceAll(RegExp(r'[:\-]'), '').toUpperCase();
  if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(hex) ||
      hex == '020000000000' ||
      hex == '000000000000' ||
      hex == 'FFFFFFFFFFFF') {
    return null;
  }
  return '${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8)}';
}
