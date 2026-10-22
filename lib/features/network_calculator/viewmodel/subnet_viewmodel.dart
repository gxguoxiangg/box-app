/// 子网计算输入状态。后期扩展：新增计算模式使用独立 Provider。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/subnet_calculator.dart';
import '../models/subnet_result.dart';

/// 输入与结果同步的不可变快照。
class SubnetState {
  /// 从输入创建状态；错误期间不保留过期结果。
  SubnetState(List<String> octets, this.prefix)
    : octets = List.unmodifiable(octets) {
    try {
      result = SubnetCalculator().calculate(octets, prefix);
      error = null;
    } on FormatException catch (e) {
      error = e.message;
      result = null;
    }
  }

  /// 四段原始输入。
  final List<String> octets;

  /// 前缀长度。
  final int prefix;

  /// 当前有效结果。
  late final SubnetResult? result;

  /// 输入错误。
  late final String? error;
}

/// 离开页面自动清空输入，避免重新进入时输入框与结果不一致。
final subnetProvider =
    NotifierProvider.autoDispose<SubnetViewModel, SubnetState>(
      SubnetViewModel.new,
    );

/// 同步驱动本地换算。
class SubnetViewModel extends Notifier<SubnetState> {
  @override
  SubnetState build() => SubnetState(['192', '168', '10', '1'], 24);

  /// 更新一段地址。
  void setOctet(int index, String value) {
    final octets = [...state.octets];
    octets[index] = value;
    state = SubnetState(octets, state.prefix);
  }

  /// 设计稿滑块支持 /1 到 /32，服务本身也可处理 /0。
  void setPrefix(int value) =>
      state = SubnetState(state.octets, value.clamp(1, 32));
}
