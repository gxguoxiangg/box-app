/// ApiClient 的 Riverpod 依赖注入。
///
/// 使用 Provider 注册单例，任何 Repository 只需通过 `ref.watch(apiClientProvider)`
/// 获取实例，而不必关心其创建与销毁，便于后期替换或 Mock。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// 全局唯一的 ApiClient 实例。
final apiClientProvider = Provider<ApiClient>((ref) {
  // 简单起见直接创建；后续如需在热重载/退出时释放，可在此管理生命周期。
  return ApiClient();
});
