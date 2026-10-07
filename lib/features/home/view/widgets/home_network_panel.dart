/// 主页网络摘要面板。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/busybox_palette.dart';
import '../../../../shared/widgets/busybox_card.dart';
import 'connection_activity.dart';

import '../../../network/models/connection_type.dart';
import '../../../network/models/network_info_data.dart';
import '../../../network/data/wifi_access_permission.dart';
import '../../viewmodel/home_network_viewmodel.dart';

/// 展示连接类型、IP、子网掩码、网关与 Wi-Fi 接入点 MAC。
class HomeNetworkPanel extends ConsumerWidget {
  /// 创建网络摘要面板。
  const HomeNetworkPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BusyBoxPalette palette = BusyBoxPalette.of(context);
    final AsyncValue<HomeNetworkSnapshot> state = ref.watch(
      homeNetworkSnapshotProvider,
    );
    final HomeNetworkSnapshot? snapshot = state.value;
    final NetworkInfoData? info = snapshot?.info;
    final bool isConnected =
        snapshot?.status.type != ConnectionType.none && snapshot != null;
    return BusyBoxCard(
      key: const ValueKey<String>('home-network-panel'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lan_outlined, size: 20, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        '当前网络信息',
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConnectionActivity(connected: isConnected),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.canvas,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isConnected ? palette.success : palette.subtle,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isLoading ? '检测中' : snapshot?.badgeLabel ?? '无连接',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: palette.border),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _NetworkValueTile(
                  label: 'IPv4 地址',
                  value: info?.ipv4,
                  palette: palette,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NetworkValueTile(
                  label: '子网掩码',
                  value: info?.subnetMask,
                  palette: palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _NetworkValueTile(
            label: 'IPv6 地址',
            value: info?.ipv6,
            icon: Icons.public_rounded,
            palette: palette,
          ),
          const SizedBox(height: 10),
          _NetworkValueTile(
            label: '默认网关',
            value: info?.gateway,
            icon: Icons.dns_outlined,
            palette: palette,
          ),
          const SizedBox(height: 10),
          _NetworkValueTile(
            label: 'Wi-Fi 接入点 MAC',
            value: info?.accessPointMac,
            icon: Icons.fingerprint_rounded,
            palette: palette,
          ),
          if (info?.accessPointMac == null && WifiAccessPermission.supported)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: const Text('授权读取接入点 MAC'),
                onPressed: () async {
                  final bool granted = await WifiAccessPermission.request();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        granted
                            ? '已重新读取；若仍无结果，请开启系统定位并连接 Wi-Fi'
                            : '需要位置权限才能读取 Wi-Fi 接入点 MAC',
                      ),
                    ),
                  );
                  if (granted) ref.invalidate(homeNetworkSnapshotProvider);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NetworkValueTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? icon;
  final BusyBoxPalette palette;

  const _NetworkValueTile({
    required this.label,
    required this.value,
    required this.palette,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final String displayValue = value?.trim().isNotEmpty == true
        ? value!.trim()
        : '—';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: displayValue == '—'
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: displayValue));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('已复制$label')));
              }
            },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.inset,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: palette.subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, size: 14, color: palette.subtle),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.ink,
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 后期扩展：需要设备自身 MAC 时应增加独立字段与平台策略，不能将接入点 BSSID 混用。
