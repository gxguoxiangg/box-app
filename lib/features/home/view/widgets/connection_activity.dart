/// 连接状态的装饰动效，不采集或表示实际流量。
/// 后期扩展：真实速率监测应另建数据模型，不能用此动画代替测量值。
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/busybox_palette.dart';

/// 已连接时播放三根柱条；无连接、减少动画、后台或路由不可见时停播。
class ConnectionActivity extends StatefulWidget {
  /// 创建连接状态动效。
  const ConnectionActivity({super.key, required this.connected});

  /// 是否检测到网络连接；不代表互联网可达。
  final bool connected;

  @override
  State<ConnectionActivity> createState() => _ConnectionActivityState();
}

class _ConnectionActivityState extends State<ConnectionActivity>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(ConnectionActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncAnimation();
  }

  void _syncAnimation() {
    final bool animate =
        widget.connected &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BusyBoxPalette palette = BusyBoxPalette.of(context);
    return Tooltip(
      message: '连接状态动效，非实时流量',
      child: Semantics(
        label: widget.connected ? '网络已连接，状态动效，非实时流量' : '无网络连接',
        child: SizedBox(
          width: 12,
          height: 14,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(
                3,
                (index) => Container(
                  width: 2,
                  height: widget.connected
                      ? 4 +
                            8 *
                                (0.5 +
                                    0.5 *
                                        math.sin(
                                          (_controller.value + index / 3) *
                                              math.pi *
                                              2,
                                        ))
                      : 4,
                  decoration: BoxDecoration(
                    color: widget.connected ? palette.accent : palette.subtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
