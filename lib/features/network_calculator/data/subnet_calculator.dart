/// 本地计算服务。后期扩展：POE、带宽各自使用独立计算服务。
library;

import 'dart:math' as math;
import '../models/subnet_result.dart';

/// 无网络依赖的 IPv4 子网计算器。
class SubnetCalculator {
  /// 校验地址和前缀后计算；非法输入不自动替换成另一个地址。
  SubnetResult calculate(List<String> octets, int prefix) {
    if (prefix < 0 || prefix > 32) {
      throw const FormatException('前缀长度必须为 0–32');
    }
    if (octets.length != 4 ||
        octets.any(
          (v) => !RegExp(r'^\d{1,3}$').hasMatch(v) || int.parse(v) > 255,
        )) {
      throw const FormatException('请填写完整 IPv4 地址，每段为 0–255');
    }
    final ip = octets.fold<int>(
      0,
      (value, part) => value * 256 + int.parse(part),
    );
    // 使用整数除法与取余，避免 Web 的 32 位位运算产生符号/移位差异。
    final total = math.pow(2, 32 - prefix).toInt();
    final start = (ip ~/ total) * total;
    final end = start + total - 1;
    return SubnetResult(
      mask: _address(4294967296 - total),
      network: _address(start),
      broadcast: prefix >= 31 ? null : _address(end),
      firstHost: _address(prefix >= 31 ? start : start + 1),
      lastHost: _address(prefix >= 31 ? end : end - 1),
      totalHosts: total,
      usableHosts: prefix >= 31 ? total : total - 2,
      prefix: prefix,
    );
  }

  String _address(int value) => [
    (value ~/ 16777216) % 256,
    (value ~/ 65536) % 256,
    (value ~/ 256) % 256,
    value % 256,
  ].join('.');
}
