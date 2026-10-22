/// 神机 Repository；与 Wiki 使用不同的 ApiClient 和认证。
/// 后期扩展：按表检索或写入仍应封装于本层，不在 View 中发送 HTTP。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/iadb_models.dart';

/// 服务地址，可用 --dart-define=IADB_API_BASE_URL=... 替换。
const iadbBaseUrl = String.fromEnvironment(
  'IADB_API_BASE_URL',
  defaultValue: 'http://159.75.86.98:10001',
);

/// 独立客户端，可在测试中注入 MockClient。
final iadbApiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: iadbBaseUrl);
  ref.onDispose(client.dispose);
  return client;
});

/// 神机数据仓库。
final iadbRepositoryProvider = Provider(
  (ref) => IadbRepository(ref.watch(iadbApiClientProvider)),
);

/// 封装认证与查询接口，不保存用户密码。
class IadbRepository {
  /// 注入客户端。
  IadbRepository(this.client);

  /// HTTP 封装。
  final ApiClient client;

  /// 登录。
  Future<IadbSession> login(String username, String password) async =>
      IadbSession.fromJson(
        await client.requestJson(
          '/api/v1/auth/login',
          method: 'POST',
          body: {'username': username, 'password': password},
        ),
      );

  /// 刷新时替换两种令牌。
  Future<IadbSession> refresh(IadbSession session) async =>
      IadbSession.fromJson(
        await client.requestJson(
          '/api/v1/auth/refresh',
          method: 'POST',
          body: {'refresh_token': session.refreshToken},
        ),
        fallbackName: session.username,
      );

  /// 注销当前会话。
  Future<void> logout(String token) async {
    await client.requestJson(
      '/api/v1/auth/logout',
      method: 'POST',
      token: token,
    );
  }

  /// 全表搜索，使用 URI 编码，百分号和下划线保持字面参数。
  Future<IadbResults> search(String token, String query, int offset) async {
    final q = query.trim();
    if (q.runes.isEmpty ||
        q.runes.length > 128 ||
        offset < 0 ||
        offset > 1000000) {
      throw const ApiException('请输入 1–128 个字符，分页范围不能超过服务限制');
    }
    final result = IadbResults.fromJson(
      await client.requestJson(
        '/api/v1/search',
        token: token,
        query: {'q': q, 'limit': '20', 'offset': '$offset'},
      ),
    );
    // 搜索只返回直接关联对象，父级需通过 parent_id 读取。
    // 缓存限定在单次搜索内：避免重复请求，也不会跨账号复用数据。
    final parents = <String, Future<Map<String, Object?>>>{};
    Future<Map<String, Object?>> parent(
      String table,
      Map<String, Object?> row,
    ) {
      final id = row['parent_id'];
      if (id is! int || id <= 0 || id == row['id']) {
        return Future.value(const {});
      }
      return parents.putIfAbsent('$table/$id', () async {
        try {
          return await client.requestJson(
            '/api/v1/tables/$table/$id',
            token: token,
          );
        } on ApiException catch (error) {
          if (error.statusCode == 404) return const {};
          rethrow;
        }
      });
    }

    final assets = <IadbAsset>[];
    for (final item in result.assets) {
      final context = Map<String, Object?>.of(item.context);
      context['department_parent'] ??= await parent(
        'department',
        iadbObject(context['department']),
      );
      final location = iadbObject(context['location']);
      final directParent = await parent('location', location);
      context['location_parent2'] ??= directParent;
      // 只展开两层，并避免异常循环关系把当前位置再次放进路径。
      final ancestor = directParent['parent_id'] == location['id']
          ? const <String, Object?>{}
          : await parent('location', directParent);
      context['location_parent1'] ??= ancestor;
      assets.add(IadbAsset(context));
    }
    return IadbResults(
      assets: assets,
      records: result.records,
      assetCount: result.assetCount,
      recordCount: result.recordCount,
      offset: result.offset,
      limit: result.limit,
    );
  }
}
