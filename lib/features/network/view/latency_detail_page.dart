/// 延迟测试详情页。
///
/// 展示单个网站的连通延迟详细信息。
/// 当前为**简化设计**，后期可在此迭代升级（如历史记录、图表、多次采样等）。
library;

import 'package:flutter/material.dart';

import '../models/latency_result.dart';

/// 延迟详情页。
class LatencyDetailPage extends StatelessWidget {
  /// 对应的延迟测试结果。
  final LatencyResult result;

  const LatencyDetailPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('延迟详情'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // 顶部：主机名 + 状态
          _buildHeader(),
          const SizedBox(height: 16),
          // 信息列表
          _buildDetailTile(context, '目标主机', result.host),
          _buildDetailTile(context, '完整地址', result.url),
          _buildDetailTile(context, '连通状态', result.success ? '可达' : '不可达'),
          _buildDetailTile(
            context,
            '延迟',
            result.success ? '${result.latencyMs} ms' : '—',
          ),
          _buildDetailTile(context, '测试时间', '${result.testedAt.toLocal()}'),
          const SizedBox(height: 24),
          // 占位提示：说明当前为简化版本
          const Text(
            '说明：当前为简化版详情，后期将支持多次采样、延迟曲线等高级功能。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 顶部状态头。
  Widget _buildHeader() {
    final bool ok = result.success;
    final Color color = ok ? const Color(0xFF00A87E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 40,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.displayText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 单行「字段：值」。
  Widget _buildDetailTile(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
