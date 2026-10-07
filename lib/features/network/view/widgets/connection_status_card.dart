/// 网络连接状态卡片（页面顶部）。
///
/// 展示当前连接类型与 Wi-Fi 名称：
/// - 连接了 Wi-Fi → 显示 Wi-Fi 名称；
/// - 移动数据 → 显示「移动数据」；
/// - 无互联网 → 显示「无连接」。
library;

import 'package:flutter/material.dart';

import '../../models/connection_type.dart';
import '../../models/network_status.dart';

/// 连接状态卡片。
class ConnectionStatusCard extends StatelessWidget {
  final NetworkStatus status;

  const ConnectionStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // 根据连接类型决定强调色。
    final Color accent = _accentColor(status.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          // 连接类型图标
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(status.type.icon, size: 30, color: accent),
          ),
          const SizedBox(width: 16),
          // 文案
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '当前网络',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 各连接类型的强调色。
  Color _accentColor(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
        return const Color(0xFF00A87E);
      case ConnectionType.mobile:
        return const Color(0xFF3B6CF6);
      case ConnectionType.vpn:
        return const Color(0xFF6750A4);
      case ConnectionType.ethernet:
        return const Color(0xFF8B5CF6);
      case ConnectionType.bluetooth:
        return const Color(0xFF06B6D4);
      case ConnectionType.none:
        return const Color(0xFF9CA3AF);
      case ConnectionType.other:
        return const Color(0xFFF59E0B);
    }
  }
}
