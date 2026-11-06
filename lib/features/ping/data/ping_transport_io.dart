import 'ping_output.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/ping_models.dart';
import 'ping_transport.dart';

/// Android 使用系统 ICMP Ping；无 shell 拼接。
PingTransport createTransport() => _AndroidPing();

class _AndroidPing implements PingTransport {
  final _active = <Process>{};
  int _generation = 0;
  @override
  bool get supported => Platform.isAndroid;
  @override
  Future<double?> probe(String target, int bytes, int timeoutMs) async {
    if (!supported) throw UnsupportedError('仅支持 Android');
    if (!PingConfig.validTarget(target)) throw const FormatException('目标无效');
    final generation = _generation;
    final process = await Process.start(
      '/system/bin/ping',
      [
        '-n',
        '-c',
        '1',
        '-s',
        '$bytes',
        '-W',
        '${(timeoutMs / 1000).ceil()}',
        target,
      ],
      environment: {'LC_ALL': 'C'},
    );
    if (generation != _generation) {
      process.kill();
      return null;
    }
    _active.add(process);
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();
    try {
      final code = await process.exitCode.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
      final text = await output;
      final errorText = await errors;
      if (code == -1 || code == 1) return null;
      if (code != 0) {
        throw StateError(
          errorText.contains('Operation not permitted')
              ? '系统不允许 ICMP 探测'
              : '无法探测，请检查目标解析或系统 Ping 支持',
        );
      }
      return parsePingLatency(text);
    } finally {
      _active.remove(process);
      process.kill();
    }
  }

  @override
  void cancel() {
    _generation++;
    for (final process in _active.toList()) {
      process.kill();
    }
    _active.clear();
  }
}
