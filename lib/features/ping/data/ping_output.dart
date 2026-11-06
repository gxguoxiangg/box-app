/// 解析系统 ping 的实际往返时延；不接受丢包汇总中的数字。
/// 后期扩展：平台输出差异集中在这里，并补充合成样本测试。
double parsePingLatency(String output) {
  final match = RegExp(r'time([=<])\s*([0-9.]+)\s*ms').firstMatch(output);
  final value = double.tryParse(match?.group(2) ?? '');
  if (value == null || !value.isFinite || value < 0) {
    throw const FormatException('系统 Ping 响应无法解析');
  }
  // 小于某阈值时以阈值作保守上界；Android 常见格式为 time=。
  return value;
}
