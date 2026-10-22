/// 神机响应模型。关联详情保留原始字段，避免遗漏历史或未分配资产记录。
library;

import '../../../core/network/api_client.dart';

/// 将 JSON 对象转换为安全的字段映射。
Map<String, Object?> iadbObject(Object? value) =>
    value is Map<String, Object?> ? Map.unmodifiable(value) : const {};

/// 将 JSON 数组转换为对象列表。
List<Map<String, Object?>> iadbObjects(Object? value) => value is List
    ? value
          .whereType<Map<String, Object?>>()
          .map(iadbObject)
          .toList(growable: false)
    : const [];

/// 可显示字段，空值使用占位符。
String iadbText(Object? value) =>
    value == null || value.toString().trim().isEmpty ? '—' : value.toString();

/// 内存会话，不提供日志序列化或持久化。
class IadbSession {
  /// 创建会话。
  const IadbSession(
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.username,
  );

  /// 访问令牌。
  final String accessToken;

  /// 轮换刷新令牌，仅存内存。
  final String refreshToken;

  /// 访问到期时间。
  final DateTime expiresAt;

  /// 显示用账号名。
  final String username;

  /// 严格校验认证响应，不能把空 2xx 当作登录成功。
  factory IadbSession.fromJson(
    Map<String, Object?> json, {
    String fallbackName = '',
  }) {
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    final seconds = json['expires_in'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty ||
        seconds is! int ||
        seconds <= 0) {
      throw const ApiException('登录响应无效');
    }
    return IadbSession(
      access,
      refresh,
      DateTime.now().add(Duration(seconds: seconds.toInt())),
      switch (iadbObject(json['user'])['username']) {
        final String name => name,
        _ => fallbackName,
      },
    );
  }
}

/// 搜索返回的一项资产及其直接关联上下文。
class IadbAsset {
  /// 创建只读资产视图。
  IadbAsset(Map<String, Object?> json) : context = Map.unmodifiable(json);

  /// 完整关联上下文，用于详情展示。
  final Map<String, Object?> context;

  /// 资产原始字段。
  Map<String, Object?> get asset => iadbObject(context['asset']);

  /// 资产 ID。
  int? get id => (asset['id'] as num?)?.toInt();

  /// 标题按实际可用信息降级。
  String get title => iadbText(
    asset['name'] ??
        asset['description'] ??
        asset['asset_code'] ??
        asset['asset_type'],
  );

  /// 负责人。
  String get owner => iadbText(iadbObject(context['owner'])['name']);

  /// 资产所属部门，按父级到当前部门排列；缺失层级不生成空分隔符。
  String get department => _hierarchy(['department_parent', 'department']);

  /// 位置按接口约定的 parent1、parent2、当前位置顺序展示。
  String get location =>
      _hierarchy(['location_parent1', 'location_parent2', 'location']);

  String _hierarchy(List<String> keys) {
    final names = keys
        .map((key) {
          final value = context[key];
          return iadbText(
            value is String ? value : iadbObject(value)['name'],
          ).trim();
        })
        .where((name) => name.isNotEmpty && name != '—');
    return names.isEmpty ? '—' : names.join(' · ');
  }

  /// 创建时间显示至分钟，保留服务端时间所表达的钟面值，不隐式转换时区。
  /// 后期扩展：如需统一时区，应先明确后端时间约定，再集中调整这里。
  String get createdAtLabel {
    final raw = asset['created_at'];
    if (raw is! String) return '—';
    final text = raw.trim();
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(text);
    if (match == null || DateTime.tryParse(text) == null) return '—';
    final year = int.parse(match[1] ?? '0');
    final month = int.parse(match[2] ?? '0');
    final day = int.parse(match[3] ?? '0');
    final date = DateTime.utc(year, month, day);
    if (date.year != year ||
        date.month != month ||
        date.day != day ||
        int.parse(match[4] ?? '0') > 23 ||
        int.parse(match[5] ?? '0') > 59 ||
        int.parse(match[6] ?? '0') > 59) {
      return '—';
    }
    return '${match[1]}-${match[2]}-${match[3]} ${match[4]}:${match[5]}';
  }

  /// 网卡。
  List<Map<String, Object?>> get interfaces =>
      iadbObjects(context['interfaces']);

  /// 全部可用 IP，不假设只有一块网卡。
  List<String> get ips => interfaces
      .expand((item) => iadbObjects(item['ip_addresses']))
      .map((item) => iadbText(item['ip_address']))
      .where((v) => v != '—')
      .toSet()
      .toList();

  /// 全部可用 MAC。
  List<String> get macs => interfaces
      .map((item) => iadbText(item['mac_address']))
      .where((v) => v != '—')
      .toSet()
      .toList();
}

/// 两组独立分页的搜索结果；不得将记录和资产按下标配对。
class IadbResults {
  /// 创建结果页。
  const IadbResults({
    required this.assets,
    required this.records,
    required this.assetCount,
    required this.recordCount,
    required this.offset,
    required this.limit,
  });

  /// 当前资产页。
  final List<IadbAsset> assets;

  /// 当前命中记录页，包括无关联资产的记录。
  final List<Map<String, Object?>> records;

  /// 命中资产总数。
  final int assetCount;

  /// 命中记录总数。
  final int recordCount;

  /// 当前偏移。
  final int offset;

  /// 每页条数。
  final int limit;

  /// 任一结果组尚有下一页时允许翻页。
  bool get hasNext =>
      offset + limit < assetCount || offset + limit < recordCount;

  /// 校验搜索外层结构。
  factory IadbResults.fromJson(Map<String, Object?> json) {
    if (json['assets'] is! List ||
        json['matched_records'] is! List ||
        json['matched_asset_count'] is! int ||
        json['matched_record_count'] is! int ||
        json['offset'] is! int ||
        json['limit'] is! int ||
        (json['limit'] as int) <= 0 ||
        (json['limit'] as int) > 100 ||
        (json['offset'] as int) < 0 ||
        (json['matched_asset_count'] as int) < 0 ||
        (json['matched_record_count'] as int) < 0 ||
        !(json['assets'] as List).every(
          (row) =>
              row is Map<String, Object?> &&
              row['asset'] is Map<String, Object?>,
        ) ||
        !(json['matched_records'] as List).every(
          (row) =>
              row is Map<String, Object?> &&
              row['record'] is Map<String, Object?>,
        )) {
      throw const ApiException('搜索响应无效');
    }
    return IadbResults(
      assets: iadbObjects(json['assets']).map(IadbAsset.new).toList(),
      records: iadbObjects(json['matched_records']),
      assetCount: json['matched_asset_count'] as int,
      recordCount: json['matched_record_count'] as int,
      offset: json['offset'] as int,
      limit: json['limit'] as int,
    );
  }
}
