/// 单次连通性延迟测试结果模型。
///
/// 对应一个网站（host）的测试结果：成功时记录耗时，失败时标记不可达。
library;

/// 延迟测试结果。
class LatencyResult {
  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 测试目标主机名（如 `www.baidu.com`）。
  final String host;

  /// 实际请求的完整地址（如 `https://www.baidu.com/`）。
  final String url;

  /// 是否测试成功（能建立连接并收到响应）。
  final bool success;

  /// 往返延迟（毫秒）；失败时为 null。
  final int? latencyMs;

  /// 测试时间。
  final DateTime testedAt;

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const LatencyResult({
    required this.host,
    required this.url,
    required this.success,
    required this.testedAt,
    this.latencyMs,
  });

  /// 卡片展示主文案：成功显示「xx ms」，失败显示「不可达」。
  String get displayText => success ? '$latencyMs ms' : '不可达';
}
