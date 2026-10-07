/// 主页系列界面共用的圆角卡片与入场反馈。
/// 后期扩展：调整卡片圆角和阴影时集中修改此组件，颜色继续由配色模板提供。
library;

import 'package:flutter/material.dart';
import '../../core/theme/busybox_palette.dart';

/// 支持水波纹和按压缩放的主题卡片。
class BusyBoxCard extends StatefulWidget {
  /// 创建卡片；没有点击行为的面板不显示按压反馈。
  const BusyBoxCard({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 20,
    this.color,
    this.padding = EdgeInsets.zero,
  });

  /// 卡片内容。
  final Widget child;

  /// 点击行为。
  final VoidCallback? onTap;

  /// 卡片圆角。
  final double radius;

  /// 可选底色，默认使用面板色。
  final Color? color;

  /// 内容内边距。
  final EdgeInsetsGeometry padding;

  @override
  State<BusyBoxCard> createState() => _BusyBoxCardState();
}

class _BusyBoxCardState extends State<BusyBoxCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final BusyBoxPalette palette = BusyBoxPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(widget.radius);
    return AnimatedScale(
      scale: _pressed && widget.onTap != null ? 0.975 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.ink.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: widget.color ?? palette.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: palette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// 正文区块首次挂载时淡入上移，不影响已有品牌标题动画。
class BusyBoxEntrance extends StatelessWidget {
  /// 创建入场动画，顺序越后完成越晚。
  const BusyBoxEntrance({super.key, required this.child, this.order = 0});

  /// 内容。
  final Widget child;

  /// 错开各区块动画的顺序。
  final int order;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + order * 70),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
