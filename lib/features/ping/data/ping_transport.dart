/// 平台探测资源约定。
abstract class PingTransport {
  /// 是否支持真实 ICMP。
  bool get supported;

  /// 执行一次探测，null 表示超时或不可达。
  Future<double?> probe(String target, int bytes, int timeoutMs);

  /// 终止所有进行中的系统进程。
  void cancel();
}
