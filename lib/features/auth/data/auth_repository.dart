/// Wiki 认证数据仓库。
///
/// 认证请求集中在 Repository 中，页面和 ViewModel 不直接拼接 API 路径或表单。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../models/auth_session.dart';

/// 认证仓库。
class AuthRepository {
  final ApiClient _apiClient;

  const AuthRepository(this._apiClient);

  /// 使用用户名和密码获取 JWT。
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final Map<String, dynamic> data = await _apiClient.postFormJson(
      '${AppConstants.kbApiPrefix}/auth/login',
      <String, String>{'username': username, 'password': password},
    );
    return AuthSession.fromJson(data);
  }
}

/// 认证仓库 Provider。
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
