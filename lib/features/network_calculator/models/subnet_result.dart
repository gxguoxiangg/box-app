/// IPv4 子网的计算结果，不包含任何平台或 UI 依赖。
class SubnetResult {
  /// 创建完整的结果快照。
  const SubnetResult({
    required this.mask,
    required this.network,
    required this.broadcast,
    required this.firstHost,
    required this.lastHost,
    required this.totalHosts,
    required this.usableHosts,
    required this.prefix,
  });

  /// 点分十进制掩码。
  final String mask;

  /// 网络起始地址。
  final String network;

  /// 广播地址；/31 点对点和 /32 单主机不使用广播。
  final String? broadcast;

  /// 可用范围起点。
  final String firstHost;

  /// 可用范围终点。
  final String lastHost;

  /// 地址总数。
  final int totalHosts;

  /// 按前缀语义计算的主机容量，不代表所有地址均能分配到公网。
  final int usableHosts;

  /// CIDR 前缀长度。
  final int prefix;

  /// 便于显示和复制的完整范围。
  String get range => '$firstHost ~ $lastHost';
}
