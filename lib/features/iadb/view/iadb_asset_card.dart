/// 神机设计稿的资产卡片。后期扩展：新增资产字段优先保持既有信息层次。
library;

import 'package:flutter/material.dart';
import '../../../core/theme/busybox_palette.dart';
import '../models/iadb_models.dart';

/// 按截图组织标签、网络、归属与操作区，所有值均来自实际响应。
class IadbAssetCard extends StatelessWidget {
  /// 创建资产卡片。
  const IadbAssetCard({
    super.key,
    required this.asset,
    required this.onDetails,
    required this.onCopy,
  });

  /// 资产及关联上下文。
  final IadbAsset asset;

  /// 打开详情。
  final VoidCallback onDetails;

  /// 复制真实网络字段。
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    final p = BusyBoxPalette.of(context);
    final data = asset.asset;
    final status = iadbText(data['status']);
    // 未知状态保持中性色，不将任意状态误报为在线。
    final good = {
      'active',
      'online',
      'in_use',
      '正常',
      '在用',
      '在线',
    }.contains(status.toLowerCase());
    final statusColor = good ? p.success : p.muted;
    return Card(
      key: ValueKey('iadb-asset-${asset.id}'),
      color: p.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _badge(
                            context,
                            iadbText(data['asset_type']),
                            Icons.dns_outlined,
                            p.accent,
                          ),
                          if (status != '—')
                            _badge(
                              context,
                              status,
                              Icons.circle,
                              statusColor,
                              status: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Text(
                        iadbText(data['description']),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: p.subtle,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      // 厂商与型号同行，窄屏或长文本时允许自然换行。
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            iadbText(data['vendor']),
                            key: const ValueKey('iadb-vendor-title'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: p.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (iadbText(data['model']) != '—')
                            Text(
                              iadbText(data['model']),
                              key: const ValueKey('iadb-model-label'),
                              style: TextStyle(fontSize: 16, color: p.muted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Container(
                        key: const ValueKey('iadb-permission-label'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.inset,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          iadbText(data['权限类别']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 每块网卡独立展示，避免把不同接口的 IP 与 MAC 拼在一起。
          if (asset.interfaces.isEmpty)
            _network(context, const {})
          else
            for (final interface in asset.interfaces)
              _network(context, interface),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        context,
                        '负责人',
                        asset.owner,
                        Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        context,
                        '所属部门',
                        asset.department,
                        Icons.corporate_fare,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(
                  context,
                  '位置',
                  asset.location,
                  Icons.location_on_outlined,
                ),
              ],
            ),
          ),
          Container(
            key: const ValueKey('iadb-card-footer'),
            padding: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(
              color: p.inset.withValues(alpha: 0.7),
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.update, size: 13, color: p.subtle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    asset.createdAtLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: p.subtle),
                  ),
                ),
                TextButton(
                  onPressed: onDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: p.ink,
                    minimumSize: const Size(64, 48),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('详情', style: TextStyle(fontSize: 12)),
                      Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(
    BuildContext context,
    String text,
    IconData icon,
    Color color, {
    bool status = false,
  }) {
    final p = BusyBoxPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status ? color.withValues(alpha: 0.1) : p.inset,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: status ? 6 : 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: status ? color : p.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _network(BuildContext context, Map<String, Object?> interface) {
    final p = BusyBoxPalette.of(context);
    final addresses = iadbObjects(interface['ip_addresses']);
    final allocations = addresses
        .map((ip) => iadbText(ip['allocation_type']))
        .where((v) => v != '—')
        .toSet()
        .join(' / ');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.inset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (asset.interfaces.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                iadbText(interface['interface_name']),
                style: TextStyle(fontSize: 11, color: p.subtle),
              ),
            ),
          if (addresses.isEmpty) _copyRow(context, 'IP', '—', primary: true),
          for (final ip in addresses)
            _copyRow(
              context,
              iadbText(ip['ip_address']).contains(':') ? 'IPv6' : 'IPv4',
              iadbText(ip['ip_address']),
              primary: true,
            ),
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLine(p.border),
          ),
          _copyRow(context, 'MAC', iadbText(interface['mac_address'])),
          if (allocations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                allocations,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: p.subtle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _copyRow(
    BuildContext context,
    String label,
    String value, {
    bool primary = false,
  }) {
    final p = BusyBoxPalette.of(context);
    return Semantics(
      button: value != '—',
      label: '复制 $label $value',
      child: InkWell(
        onTap: value == '—' ? null : () => onCopy(label, value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: p.muted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: primary ? 15 : 13,
                    fontWeight: primary ? FontWeight.w600 : FontWeight.normal,
                    color: primary ? p.ink : p.muted,
                  ),
                ),
              ),
              if (value != '—')
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.copy_outlined, size: 16, color: p.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final p = BusyBoxPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: p.muted)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: p.muted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: p.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashedLine extends CustomPainter {
  const _DashedLine(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 5) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + 3).clamp(0, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLine oldDelegate) => color != oldDelegate.color;
}
