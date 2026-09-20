/// Wiki 登录 ViewModel。
///
/// 负责登录请求、错误凭据计数和临时锁定；登录页只订阅状态并提交输入值。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../models/auth_session.dart';

/// 登录失败次数超过此值后暂时锁定账号登录入口。
const int maxLoginFailures = 5;

/// 登录锁定时长。
const Duration loginLockDuration = Duration(minutes: 15);

/// 登录页面状态。
class AuthState {
  /// 当前是否正在请求登录接口。
  final bool isLoading;

  /// 当前登录错误提示。
  final String? errorMessage;

  /// 连续失败次数。
  final int failedAttempts;

  /// 解锁时间；没有锁定时为 null。
  final DateTime? lockedUntil;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  /// 当前是否处于锁定状态。
  bool get isLocked {
    final DateTime? until = lockedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// 创建局部更新后的状态。
  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLock ? null : lockedUntil ?? this.lockedUntil,
    );
  }
}

/// 登录状态控制器。
class AuthController extends Notifier<AuthState> {
  Timer? _lockTimer;

  @override
  AuthState build() {
    ref.onDispose(() => _lockTimer?.cancel());
    return const AuthState();
  }

  /// 提交登录请求，成功返回会话，失败返回 null。
  Future<AuthSession?> login({
    required String username,
    required String password,
  }) async {
    if (state.isLoading) return null;

    if (state.isLocked) {
      state = state.copyWith(
        errorMessage: '登录失败次数过多，请 15 分钟后再试',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AuthSession session = await ref.read(authRepositoryProvider).login(
            username: username,
            password: password,
          );
      state = const AuthState();
      return session;
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.statusCode == null
              ? '网络异常，请稍后再试'
              : '登录失败，请稍后再试',
        );
        return null;
      }

      final int failedAttempts = state.failedAttempts + 1;
      final bool shouldLock = failedAttempts > maxLoginFailures;
      if (shouldLock) {
        _startLockTimer();
      }
      state = AuthState(
        isLoading: false,
        failedAttempts: failedAttempts,
        lockedUntil: shouldLock ? DateTime.now().add(loginLockDuration) : null,
        errorMessage: shouldLock
            ? '登录失败次数过多，请 15 分钟后再试'
            : 'ⓘ 账号或密码错误。请再试一次',
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '登录响应格式异常，请稍后再试',
      );
      return null;
    }
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer(loginLockDuration, () {
      state = const AuthState();
    });
  }
}

/// 登录状态 Provider。
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// 当前内存登录会话。
class AuthSessionController extends Notifier<AuthSession?> {
  Timer? _expiryTimer;

  @override
  AuthSession? build() {
    ref.onDispose(() => _expiryTimer?.cancel());
    return null;
  }

  /// 保存本次登录会话。
  void setSession(AuthSession session) {
    _expiryTimer?.cancel();
    state = session;
    final Duration remaining = session.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      clear();
      return;
    }
    _expiryTimer = Timer(remaining, clear);
  }

  /// 清除当前登录会话。
  void clear() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    state = null;
  }

  /// 返回仍有效的会话，过期会话会立即从内存清除。
  AuthSession? get validSession {
    final AuthSession? session = state;
    if (session == null || session.isExpired) {
      clear();
      return null;
    }
    return session;
  }
}

/// 当前登录会话 Provider。
final authSessionProvider =
    NotifierProvider<AuthSessionController, AuthSession?>(
  AuthSessionController.new,
);

/// 后期扩展：投稿接口启用后，可在这里统一添加 Bearer Token、验证过期并处理 401，
/// 页面无需感知 JWT 的存储和刷新细节。
