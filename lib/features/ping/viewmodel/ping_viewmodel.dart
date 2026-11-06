import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ping_repository.dart';
import '../models/ping_models.dart';

/// 历史刷新入口。
final pingHistoryProvider = FutureProvider(
  (ref) => ref.watch(pingHistoryRepositoryProvider).read(),
);

/// 结果页释放时停止探测。
final pingRunProvider =
    NotifierProvider.autoDispose<PingRunController, PingRunState>(
      PingRunController.new,
    );

/// 测试快照。
class PingRunState {
  /// 创建快照。
  const PingRunState({
    this.results = const [],
    this.running = false,
    this.notice,
  });

  /// 各目标独立结果。
  final List<PingTargetResult> results;

  /// 当前是否运行。
  final bool running;

  /// 停止或保存失败提示。
  final String? notice;

  /// 导出当前真实结果，不包含未发送的包。
  String get report => results.map((r) => r.report).join('\n\n');
}

/// 并行目标探测，每目标顺序发送，每次完成后更新统计。
class PingRunController extends Notifier<PingRunState> {
  int _epoch = 0;
  @override
  PingRunState build() {
    final transport = ref.watch(pingTransportProvider);
    ref.onDispose(() {
      _epoch++;
      transport.cancel();
    });
    return const PingRunState();
  }

  /// 开始或重新测试；旧响应不能覆盖新会话。
  Future<void> start(PingConfig config) async {
    stop();
    final transport = ref.read(pingTransportProvider);
    if (config.error != null || !transport.supported) {
      state = PingRunState(notice: config.error ?? '暂仅支持 Android 真实 ICMP Ping');
      return;
    }
    final epoch = ++_epoch;
    final repository = ref.read(pingHistoryRepositoryProvider);
    final timer = Stopwatch()..start();
    state = PingRunState(
      running: true,
      results: config.targets
          .map((t) => PingTargetResult(t, const []))
          .toList(),
    );
    await Future.wait(
      config.targets.asMap().entries.map((entry) async {
        for (var index = 0; index < config.count && epoch == _epoch; index++) {
          final started = timer.elapsedMilliseconds;
          double? latency;
          String? error;
          var fatal = false;
          try {
            latency = await transport.probe(
              entry.value,
              config.bytes,
              config.timeoutMs,
            );
          } catch (_) {
            error = '系统探测失败，请检查域名解析或设备 ICMP 支持';
            fatal = true;
          }
          if (epoch != _epoch) return;
          final results = [...state.results];
          final previous = results[entry.key];
          results[entry.key] = PingTargetResult(
            entry.value,
            List.unmodifiable([
              ...previous.samples,
              PingSample(
                timer.elapsedMilliseconds,
                latency,
                error: error ?? (latency == null ? '超时或不可达' : null),
              ),
            ]),
            finished: fatal || index == config.count - 1,
          );
          state = PingRunState(results: results, running: true);
          if (fatal) break;
          if (index < config.count - 1) {
            final wait = 1000 - (timer.elapsedMilliseconds - started);
            if (wait > 0) {
              await Future<void>.delayed(Duration(milliseconds: wait));
            }
          }
        }
      }),
    );
    if (epoch != _epoch) return;
    state = PingRunState(results: state.results);
    final report =
        '包大小 ${config.bytes} 字节 · 每目标 ${config.count} 次 · 超时 ${config.timeoutMs} ms\n\n${state.report}';
    try {
      await repository.save(
        report,
        results: state.results,
        bytes: config.bytes,
      );
      if (epoch == _epoch) ref.invalidate(pingHistoryProvider);
    } catch (_) {
      if (epoch == _epoch) {
        state = PingRunState(results: state.results, notice: '测试已完成，但历史保存失败');
      }
    }
  }

  /// 停止当前进程，保留已收到的数据。
  void stop() {
    _epoch++;
    ref.read(pingTransportProvider).cancel();
    state = PingRunState(
      results: state.results,
      notice: state.running ? '测试已停止，结果为部分数据' : state.notice,
    );
  }
}
