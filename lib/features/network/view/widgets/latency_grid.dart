/// 网站连通延迟网格。
///
/// 「每行 3 个」的卡片式布局，每张卡片对应一个指定网站的延迟测试结果。
/// 点击卡片进入 [LatencyDetailPage] 查看详细信息（当前为简化设计）。
library;

import 'package:flutter/material.dart';

import '../latency_detail_page.dart';
import '../../models/latency_result.dart';

/// 延迟测试网格。
class LatencyGrid extends StatelessWidget {
  final List<LatencyResult> latencies;

  const LatencyGrid({super.key, required this.latencies});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // 内嵌在 ListView 中，禁用自身滚动。
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 每行固定 3 个卡片。
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: latencies.length,
      itemBuilder: (BuildContext context, int index) {
        return _LatencyCard(result: latencies[index]);
      },
    );
  }
}

/// 单个延迟卡片。
class _LatencyCard extends StatelessWidget {
  final LatencyResult result;

  const _LatencyCard({required this.result});

  /// 按延迟/状态着色：成功偏绿，失败偏红。
  Color get _color => result.success
      ? (result.latencyMs ?? 0) < 150
          ? const Color(0xFF00A87E)
          : const Color(0xFFF59E0B)
      : const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        // 点击进入详细信息页（简化设计，后期迭代）。
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LatencyDetailPage(result: result),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 状态圆点
              Icon(
                result.success
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                size: 20,
                color: _color,
              ),
              const SizedBox(height: 6),
              // 主机名（去掉 www. 前缀，简化展示）
              Text(
                result.host.replaceFirst('www.', ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              // 延迟结果
              Text(
                result.displayText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
