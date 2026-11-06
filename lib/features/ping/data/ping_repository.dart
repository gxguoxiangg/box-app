import '../models/ping_models.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ping_transport.dart';
import 'ping_transport_stub.dart'
    if (dart.library.io) 'ping_transport_io.dart'
    as platform;

/// 后期扩展：新平台只替换 Transport，不改 UI 与统计。
final pingTransportProvider = Provider<PingTransport>((ref) {
  final transport = platform.createTransport();
  ref.onDispose(transport.cancel);
  return transport;
});

/// 本机历史读写服务。
final pingHistoryRepositoryProvider = Provider(
  (ref) => PingHistoryRepository(),
);

/// 每次运行保存一条摘要，最多50条，不保存凭据。
class PingHistoryRepository {
  static const _key = 'ping_history_v1';

  /// 读取摘要，损坏记录忽略。
  Future<List<String>> read() async =>
      (await SharedPreferences.getInstance()).getStringList(_key) ?? [];

  /// 保存已完成的诊断文本。
  Future<void> save(
    String report, {
    List<PingTargetResult> results = const [],
    int? bytes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(_key) ?? [];
    final next = [
      jsonEncode({
        'time': DateTime.now().toIso8601String(),
        'report': report,
        'bytes': bytes,
        'targets': [
          for (final r in results)
            {
              'target': r.target,
              'sent': r.sent,
              'received': r.received,
              'average': r.average,
              'loss': r.loss,
            },
        ],
      }),
      ...records,
    ].take(50).toList();
    if (!await prefs.setStringList(_key, next)) throw StateError('历史保存失败');
  }

  /// 清除本机记录。
  Future<void> clear() async {
    if (!await (await SharedPreferences.getInstance()).remove(_key)) {
      throw StateError('清除历史失败');
    }
  }
}
