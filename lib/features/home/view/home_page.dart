/// 工具盒主页。
///
/// 顶部保留首次进入动画，正文按 doc/ui/home_page.html 展示网络摘要与工具。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/busybox_palette.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/busybox_card.dart';
import '../data/tool_registry.dart';
import 'widgets/home_all_tools.dart';
import 'widgets/home_network_panel.dart';
import 'widgets/home_quick_tools.dart';

/// 主页（工具盒）。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;
    final BusyBoxPalette palette = BusyBoxPalette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // 系统状态栏透明，让抽屉及其遮罩按各自覆盖区域绘制，避免整条白色覆盖层。
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: brightness,
      ),
      child: Scaffold(
        backgroundColor: palette.page,
        drawer: const AppDrawer(),
        body: ColoredBox(
          color: palette.canvas,
          child: SafeArea(
            child: Builder(
              builder: (BuildContext scaffoldContext) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTopBar(context, scaffoldContext, palette),
                    Expanded(
                      child: ColoredBox(
                        color: palette.page,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: <Widget>[
                                const BusyBoxEntrance(
                                  child: HomeNetworkPanel(),
                                ),
                                const SizedBox(height: 16),
                                BusyBoxEntrance(
                                  order: 1,
                                  child: HomeQuickTools(
                                    onCustomize: () =>
                                        context.push(AppRoutes.customTools),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const HomeAllTools(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 构建主页顶部栏。
  ///
  /// [scaffoldContext] 必须来自 Scaffold 后代 Builder，供菜单按钮打开抽屉。
  Widget _buildTopBar(
    BuildContext context,
    BuildContext scaffoldContext,
    BusyBoxPalette palette,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: palette.canvas,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: '打开侧边栏',
            icon: const Icon(Icons.grid_view_rounded),
            color: palette.ink,
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _AnimatedHomeTitle(),
                Text(
                  'BusyBox · 工具魔盒',
                  style: TextStyle(fontSize: 11, color: palette.subtle),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '个人中心',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: palette.accent,
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('个人中心即将开放'))),
          ),
        ],
      ),
    );
  }
}

/// 主页首次打开时的标题动画。
///
/// 动画严格按需求分段执行：GuoXiang 从四个方向收缩成居中四点并消失，
/// BusyBox 随后渐隐，最后显示“主页”。组件每次重新创建时都会重新播放一次。
class _AnimatedHomeTitle extends StatefulWidget {
  const _AnimatedHomeTitle();

  @override
  State<_AnimatedHomeTitle> createState() => _AnimatedHomeTitleState();
}

class _AnimatedHomeTitleState extends State<_AnimatedHomeTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // 品牌文字从第一帧显示；停留一秒后再开始收缩和渐隐动画。
    _startTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color titleColor = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double progress = _controller.value;
          final double guoShrinkProgress = Curves.easeInCubic.transform(
            (progress / 0.24).clamp(0.0, 1.0),
          );
          final double guoDotsProgress = Curves.easeOut.transform(
            ((progress - 0.18) / 0.18).clamp(0.0, 1.0),
          );
          final double lazyProgress = Curves.easeOut.transform(
            ((progress - 0.28) / 0.40).clamp(0.0, 1.0),
          );
          final double homeProgress = Curves.easeOut.transform(
            ((progress - 0.68) / 0.32).clamp(0.0, 1.0),
          );
          return Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Opacity(
                opacity: 1 - homeProgress,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 96,
                      height: 32,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Transform.scale(
                            alignment: Alignment.center,
                            scale: 1 - 0.88 * guoShrinkProgress,
                            child: Opacity(
                              opacity: 1 - guoDotsProgress,
                              child: Text(
                                'GuoXiang',
                                style: TextStyle(
                                  color: titleColor,
                                  // fontFamily: 'ShadowsIntoLight',
                                  fontFamily: 'StardosStencil-Regular',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w300,

                                  // letterSpacing: 0.4,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: guoDotsProgress * (1 - lazyProgress),
                            child: _ConvergingDots(progress: guoDotsProgress),
                          ),
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: 1 - lazyProgress,
                      child: Text(
                        ' BusyBox',
                        style: TextStyle(
                          color: titleColor,
                          // fontFamily: 'KaushanScript',
                          // fontFamily: 'IMFellEnglishSC-Regular',
                          // fontFamily: 'StardosStencil-Regular',
                          // fontFamily: 'IMFellEnglishSC-Regular',
                          fontFamily: 'StardosStencil-Regular',
                          fontSize: 19,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: homeProgress,
                child: Transform.translate(
                  offset: Offset(-12 * (1 - homeProgress), 0),
                  child: Text(
                    '主页',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// GuoXiang 收缩阶段的四点汇聚动画。
///
/// 四个点分别从上、右、下、左向中心移动，最终横向并排成一行。
class _ConvergingDots extends StatelessWidget {
  /// 四个圆点最终状态的中心间距；统一在此调整，便于后续继续微调。
  static const double _dotSpacing = 14;

  final double progress;

  const _ConvergingDots({required this.progress});

  @override
  Widget build(BuildContext context) {
    final double eased = Curves.easeInOutCubic.transform(progress);
    return SizedBox(
      width: 48,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          _movingDot(
            start: const Offset(0, -12),
            end: const Offset(-1.5 * _dotSpacing, 0),
            progress: eased,
          ),
          _movingDot(
            start: const Offset(20, 0),
            end: const Offset(-0.5 * _dotSpacing, 0),
            progress: eased,
          ),
          _movingDot(
            start: const Offset(0, 12),
            end: const Offset(0.5 * _dotSpacing, 0),
            progress: eased,
          ),
          _movingDot(
            start: const Offset(-20, 0),
            end: const Offset(1.5 * _dotSpacing, 0),
            progress: eased,
          ),
        ],
      ),
    );
  }

  Widget _movingDot({
    required Offset start,
    required Offset end,
    required double progress,
  }) {
    return Transform.translate(
      offset: Offset.lerp(start, end, progress) ?? end,
      child: const _BlackDot(),
    );
  }
}

/// GuoXiang 收缩动画使用的黑点。
class _BlackDot extends StatelessWidget {
  const _BlackDot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 3.5,
      height: 3.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
