/// 神机会话与检索状态。后期扩展：持久化需使用安全凭据存储，不能写入普通偏好设置。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/iadb_repository.dart';
import '../models/iadb_models.dart';

/// 独立于 Wiki 的内存认证状态。
final iadbSessionProvider =
    NotifierProvider<IadbSessionController, AsyncValue<IadbSession?>>(
      IadbSessionController.new,
    );

/// 管理登录、退出和单次令牌轮换。
class IadbSessionController extends Notifier<AsyncValue<IadbSession?>> {
  int _epoch = 0;
  Future<IadbSession>? _refreshing;
  @override
  AsyncValue<IadbSession?> build() {
    ref.onDispose(() => _epoch++);
    return const AsyncData(null);
  }

  /// 登录完成前或退出后的旧请求不会恢复会话。
  Future<void> login(String username, String password) async {
    final epoch = ++_epoch;
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(iadbRepositoryProvider)
          .login(username.trim(), password);
      if (epoch == _epoch) state = AsyncData(session);
    } catch (error, stack) {
      if (epoch == _epoch) state = AsyncError(error, stack);
    }
  }

  /// 立即清空本地会话；服务端撤销失败仍向调用方报告。
  Future<void> logout() async {
    final session = state.value;
    final refreshing = _refreshing;
    ++_epoch;
    _refreshing = null;
    state = const AsyncData(null);
    if (session == null) return;
    final repository = ref.read(iadbRepositoryProvider);
    // 若轮换正在进行，撤销新令牌，避免仅撤销已经失效的旧令牌。
    IadbSession latest = session;
    if (refreshing != null) {
      try {
        latest = await refreshing;
      } catch (_) {
        /* 使用原会话尝试退出。 */
      }
    }
    await repository.logout(latest.accessToken);
  }

  Future<IadbSession> _refresh(IadbSession session, int epoch) async {
    final future = _refreshing ??= ref
        .read(iadbRepositoryProvider)
        .refresh(session);
    try {
      final renewed = await future;
      if (epoch == _epoch) state = AsyncData(renewed);
      return renewed;
    } on ApiException catch (error) {
      if (epoch == _epoch &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        ++_epoch;
        state = const AsyncData(null);
      }
      rethrow;
    } finally {
      if (identical(_refreshing, future)) _refreshing = null;
    }
  }

  /// 只读请求遇到 401 最多轮换重试一次；并发请求共享刷新操作。
  Future<T> authorized<T>(Future<T> Function(String token) action) async {
    var session = state.value;
    if (session == null) throw const ApiException('请先登录神机');
    final epoch = _epoch;
    if (session.expiresAt.isBefore(
      DateTime.now().add(const Duration(seconds: 30)),
    )) {
      session = await _refresh(session, epoch);
    }
    if (epoch != _epoch) throw const ApiException('会话已变更');
    try {
      return await action(session.accessToken);
    } on ApiException catch (error) {
      if (error.statusCode != 401 || epoch != _epoch) rethrow;
      final current = state.value;
      final renewed =
          current != null && current.accessToken != session.accessToken
          ? current
          : await _refresh(session, epoch);
      if (epoch != _epoch) throw const ApiException('会话已变更');
      try {
        return await action(renewed.accessToken);
      } on ApiException catch (retryError) {
        if (retryError.statusCode == 401 && epoch == _epoch) {
          ++_epoch;
          state = const AsyncData(null);
        }
        rethrow;
      }
    }
  }
}

/// 当前查询快照，耗时来自客户端实际计时。
class IadbSearchState {
  /// 创建查询快照。
  const IadbSearchState({
    this.query = '',
    this.result = const AsyncData(null),
    this.elapsedMs = 0,
  });

  /// 已提交的关键词。
  final String query;

  /// 当前页或请求状态。
  final AsyncValue<IadbResults?> result;

  /// 请求耗时。
  final int elapsedMs;
}

/// 离开页面即清理资产数据和关键词。
final iadbSearchProvider =
    NotifierProvider.autoDispose<IadbSearchController, IadbSearchState>(
      IadbSearchController.new,
    );

/// 忽略旧搜索响应，不把两个独立数组按位置合并。
class IadbSearchController extends Notifier<IadbSearchState> {
  int _request = 0;
  @override
  IadbSearchState build() {
    ref.onDispose(() => _request++);
    ref.listen(iadbSessionProvider, (previous, next) {
      if (next.value == null) clear();
    });
    return const IadbSearchState();
  }

  /// 清理并取消旧请求对状态的更新。
  void clear() {
    ++_request;
    state = const IadbSearchState();
  }

  /// 提交查询；翻页必须沿用已提交关键词。
  Future<void> search(String query, {int offset = 0}) async {
    final request = ++_request;
    final auth = ref.read(iadbSessionProvider.notifier);
    final repository = ref.read(iadbRepositoryProvider);
    state = IadbSearchState(query: query.trim(), result: const AsyncLoading());
    final timer = Stopwatch()..start();
    try {
      final result = await auth.authorized(
        (token) => repository.search(token, query, offset),
      );
      if (request == _request) {
        state = IadbSearchState(
          query: query.trim(),
          result: AsyncData(result),
          elapsedMs: timer.elapsedMilliseconds,
        );
      }
    } catch (error, stack) {
      if (request == _request) {
        state = IadbSearchState(
          query: query.trim(),
          result: AsyncError(error, stack),
        );
      }
    }
  }
}
