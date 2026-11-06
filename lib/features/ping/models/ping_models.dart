import 'dart:math' as math;

/// 探测参数。后期扩展：IPv6 等平台差异由探测服务处理。
class PingConfig {
  /// 创建配置。
  const PingConfig(
    this.targets, {
    this.bytes = 64,
    this.count = 4,
    this.timeoutMs = 1000,
  });

  /// 目标列表。
  final List<String> targets;

  /// 数据长度。
  final int bytes;

  /// 每个目标的次数。
  final int count;

  /// 单次超时，毫秒。
  final int timeoutMs;

  /// 校验目标和范围，不允许命令选项或 shell 字符。
  String? get error {
    if (targets.isEmpty || targets.length > 4) return '请输入 1–4 个目标';
    for (final target in targets) {
      if (!validTarget(target)) return '目标地址无效：$target';
    }
    if (targets.toSet().length != targets.length) return '目标地址不能重复';
    if (bytes < 1 || bytes > 1472) return '包大小应为 1–1472 字节';
    if (count < 1 || count > 100) return '次数应为 1–100';
    if (timeoutMs < 100 || timeoutMs > 10000) return '超时应为 100–10000 ms';
    return null;
  }

  /// 支持 IPv4 与域名，明确拒绝非法数字地址。
  static bool validTarget(String value) {
    if (value.length > 253 || value.isEmpty) return false;
    if (RegExp(r'^[0-9.]+$').hasMatch(value)) {
      final parts = value.split('.');
      return parts.length == 4 &&
          parts.every(
            (p) => RegExp(r'^\d{1,3}$').hasMatch(p) && int.parse(p) <= 255,
          );
    }
    return value
        .split('.')
        .every(
          (part) => RegExp(
            r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
          ).hasMatch(part),
        );
  }
}

/// 一次实际完成的探测，超时用 null，不将其伪造为零毫秒。
class PingSample {
  /// 创建回包结果。
  const PingSample(this.elapsedMs, this.latencyMs, {this.error});

  /// 相对测试开始的时间。
  final int elapsedMs;

  /// 往返时延。
  final double? latencyMs;

  /// 超时或平台错误。
  final String? error;
}

/// 单目标实时快照及统计。
class PingTargetResult {
  /// 创建结果。
  const PingTargetResult(this.target, this.samples, {this.finished = false});

  /// 原始目标。
  final String target;

  /// 完成的探测记录。
  final List<PingSample> samples;

  /// 是否结束。
  final bool finished;

  /// 成功时延。
  List<double> get latencies =>
      samples.map((s) => s.latencyMs).whereType<double>().toList();

  /// 已完成发送次数。
  int get sent => samples.length;

  /// 接收次数。
  int get received => latencies.length;

  /// 丢包比例；未发送时无结果。
  double? get loss => sent == 0 ? null : (sent - received) * 100 / sent;

  /// 平均值。
  double? get average =>
      received == 0 ? null : latencies.reduce((a, b) => a + b) / received;

  /// 最小值。
  double? get minimum => received == 0 ? null : latencies.reduce(math.min);

  /// 最大值。
  double? get maximum => received == 0 ? null : latencies.reduce(math.max);

  /// 总体标准差，作为 mdev。
  double? get mdev {
    final avg = average;
    return avg == null
        ? null
        : math.sqrt(
            latencies.fold<double>(0, (v, x) => v + math.pow(x - avg, 2)) /
                received,
          );
  }

  /// 可复制的真实统计摘要。
  String get report =>
      '$target\n发送 $sent，接收 $received，丢包 ${number(loss)}%\n平均 ${number(average)} ms，最小 ${number(minimum)} ms，最大 ${number(maximum)} ms，Mdev ${number(mdev)} ms';

  /// 无数据统一占位。
  static String number(double? value) => value?.toStringAsFixed(2) ?? '—';
}
