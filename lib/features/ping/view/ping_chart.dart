import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/busybox_palette.dart';
import '../models/ping_models.dart';

/// 每目标的实际采样图，丢包处断线，点击查看最近一次样本。
class PingChart extends StatefulWidget {
  /// 创建实时图表。
  const PingChart({
    super.key,
    required this.result,
    this.running = false,
    this.count = 0,
  });

  /// 正在探测时显示实时采样状态。
  final bool running;

  /// 计划采样次数。
  final int count;

  /// 当前目标数据。
  final PingTargetResult result;
  @override
  State<PingChart> createState() => _PingChartState();
}

class _PingChartState extends State<PingChart> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final index = selected;
    final sample = index != null && index < result.samples.length
        ? result.samples[index]
        : null;
    final p = BusyBoxPalette.of(context);
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.show_chart, size: 18, color: p.accent),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                '延迟趋势',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '━ ${widget.running ? '实时均值' : '平均'} ${PingTargetResult.number(result.average)}ms',
              style: TextStyle(fontSize: 12, color: p.muted),
            ),
          ],
        ),
        if (widget.running)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '采样 ${result.sent}/${widget.count}',
              style: TextStyle(fontSize: 10, color: p.accent),
            ),
          ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) => GestureDetector(
            onTapUp: (event) {
              if (result.samples.isEmpty) return;
              final x =
                  ((event.localPosition.dx - 38) / math.max(1, c.maxWidth - 48))
                      .clamp(0, 1);
              final time = x * math.max(1000, result.samples.last.elapsedMs);
              var nearest = 0;
              for (var i = 1; i < result.samples.length; i++) {
                if ((result.samples[i].elapsedMs - time).abs() <
                    (result.samples[nearest].elapsedMs - time).abs()) {
                  nearest = i;
                }
              }
              setState(() => selected = nearest);
            },
            child: Semantics(
              label: '延迟趋势，${result.sent}次探测，${result.received}次回包',
              child: SizedBox(
                height: 144,
                width: double.infinity,
                child: CustomPaint(painter: _ChartPainter(result, p)),
              ),
            ),
          ),
        ),
        Text(
          sample == null
              ? (widget.running
                    ? '正在采样第 #${result.sent + 1} 包数据'
                    : '点击节点查看各次精确耗时')
              : '第 ${(index ?? 0) + 1} 次 · ${(sample.elapsedMs / 1000).toStringAsFixed(1)}s · ${sample.latencyMs == null ? sample.error ?? '未收到回包' : '${PingTargetResult.number(sample.latencyMs)} ms'}',
          style: TextStyle(fontSize: 12, color: p.muted),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.result, this.palette);
  final PingTargetResult result;
  final BusyBoxPalette palette;
  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0, top = 22.0;
    final width = math.max(1.0, size.width - left - 10),
        height = size.height - 52;
    final maximum = math.max(1.0, (result.maximum ?? 1) * 1.2);
    final duration = result.samples.isEmpty
        ? 1000
        : math.max(1000, result.samples.last.elapsedMs);
    final line = Paint()
      ..color = palette.border
      ..strokeWidth = 1;
    void label(String text, Offset point) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: palette.muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, point);
      painter.dispose();
    }

    label('延时 (ms)', Offset.zero);
    for (var i = 0; i <= 4; i++) {
      final y = top + height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), line);
      label((maximum * (4 - i) / 4).toStringAsFixed(1), Offset(0, y - 6));
      label(
        '${(duration * i / 4000).toStringAsFixed(1)}s',
        Offset(left + width * i / 4 - 10, top + height + 8),
      );
    }
    final average = result.average;
    if (average != null) {
      final y = top + height * (1 - average / maximum);
      final dash = Paint()
        ..color = palette.accent.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      for (double x = left; x < left + width; x += 8) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 4, left + width), y),
          dash,
        );
      }
    }
    Offset? previous;
    final blue = Paint()
      ..color = palette.accent
      ..strokeWidth = 2;
    for (final sample in result.samples) {
      final x = left + width * sample.elapsedMs / duration;
      final latency = sample.latencyMs;
      if (latency == null) {
        canvas.drawCircle(
          Offset(x, top + height),
          3,
          Paint()..color = palette.error,
        );
        previous = null;
        continue;
      }
      final point = Offset(x, top + height * (1 - latency / maximum));
      if (previous != null) {
        final fill = Path()
          ..moveTo(previous.dx, top + height)
          ..lineTo(previous.dx, previous.dy)
          ..lineTo(point.dx, point.dy)
          ..lineTo(point.dx, top + height)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.accent.withValues(alpha: .32),
                palette.accent.withValues(alpha: .02),
              ],
            ).createShader(Rect.fromLTWH(left, top, width, height)),
        );
        canvas.drawLine(previous, point, blue);
      }
      canvas.drawCircle(point, 3.5, Paint()..color = palette.accent);
      previous = point;
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) =>
      oldDelegate.result != result || oldDelegate.palette != palette;
}
