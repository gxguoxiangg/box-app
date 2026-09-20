/// Wiki 登录会话模型。
///
/// 对应 `POST /api/v1/auth/login` 的成功响应。当前版本只保存内存中的会话，
/// 后续接入投稿接口时可在数据层增加安全存储与过期校验。
library;

/// 登录成功后返回的 JWT 会话信息。
class AuthSession {
  /// JWT 访问令牌。
  final String accessToken;

  /// Token 类型，后端当前返回 bearer。
  final String tokenType;

  /// Token 有效期（秒）。
  final int expiresIn;

  /// 登录用户名。
  final String username;

  /// App 侧认证失效时间；按需求固定为登录成功后 1 小时。
  final DateTime expiresAt;

  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.username,
    required this.expiresAt,
  });

  /// 会话是否已经超过 App 允许的保留时间。
  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  /// 从登录接口响应构建会话模型。
  factory AuthSession.fromJson(
    Map<String, dynamic> json, {
    DateTime? authenticatedAt,
  }) {
    final String accessToken = json['access_token'] as String? ?? '';
    if (accessToken.trim().isEmpty) {
      throw const FormatException('登录响应缺少 access_token');
    }
    final Map<String, dynamic> user =
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final DateTime loginTime = authenticatedAt ?? DateTime.now();
    return AuthSession(
      accessToken: accessToken,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      username: user['username'] as String? ?? '',
      // 即使后端 Token 的有效期更长，App 也只保留一小时认证。
      expiresAt: loginTime.add(const Duration(hours: 1)),
    );
  }
}

/// 后期扩展：投稿功能启用后，在此模型中增加过期时间计算和安全持久化标记，
/// 并由统一认证 Provider 在收到 401 时清除会话。
