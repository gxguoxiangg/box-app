/// 设备网络信息卡片。
///
/// 以「两列网格」展示 IP 地址、MAC、网关等详细信息。
/// 值为 null 的字段统一显示「—」，避免空指针与排版错位。
///
/// 扩展说明：字段定义在 [_infoItems] 中，后期新增字段（如信道、频段）
/// 只需在 [NetworkInfoData] 与列表中各加一项即可。
library;

import 'package:flutter/material.dart';

import '../../models/network_info_data.dart';

/// 设备网络信息卡片。
class NetworkInfoCard extends StatelessWidget {
  final NetworkInfoData info;

  const NetworkInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final List<_InfoItem> items = _buildItems(info);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 标题
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '设备信息',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        // 信息网格
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final _InfoItem item in items) _buildTile(context, item),
          ],
        ),
      ],
    );
  }

  /// 单个信息瓦片（固定宽度，两列排列）。
  Widget _buildTile(BuildContext context, _InfoItem item) {
    final double width = (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 字段名
          Row(
            children: <Widget>[
              Icon(item.icon, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 字段值
          Text(
            item.value ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// 将模型转为可渲染的字段列表（集中维护展示配置）。
  List<_InfoItem> _buildItems(NetworkInfoData info) {
    return <_InfoItem>[
      _InfoItem(icon: Icons.language_rounded, label: 'IP 地址', value: info.ipv4),
      _InfoItem(icon: Icons.lan_rounded, label: 'IPv6', value: info.ipv6),
      _InfoItem(
        icon: Icons.network_check_rounded,
        label: '子网掩码',
        value: info.subnetMask,
      ),
      _InfoItem(
        icon: Icons.alt_route_rounded,
        label: '网关',
        value: info.gateway,
      ),
      _InfoItem(
        icon: Icons.wifi_rounded,
        label: 'Wi-Fi (SSID)',
        value: info.ssid,
      ),
      _InfoItem(
        icon: Icons.wifi_tethering_rounded,
        label: 'BSSID',
        value: info.bssid,
      ),
      _InfoItem(
        icon: Icons.broadcast_on_home_rounded,
        label: '广播地址',
        value: info.broadcast,
      ),
      _InfoItem(
        icon: Icons.memory_rounded,
        label: 'MAC 地址',
        value: info.macAddress,
      ),
    ];
  }
}

/// 单条信息的展示配置。
class _InfoItem {
  final IconData icon;
  final String label;
  final String? value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
