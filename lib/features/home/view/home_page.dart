/// 工具盒主页。
///
/// 顶部栏包含菜单、首次进入动画标题和搜索入口；下方为分类导航与功能网格。
/// 页面只负责布局和路由，功能数据由 HomeViewModel 提供。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../data/tool_registry.dart';
import 'widgets/category_bar.dart';
import 'widgets/tool_grid.dart';

/// 主页（工具盒）。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.scaffoldBackgroundColor,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: brightness,
      ),
      child: Scaffold(
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Builder(
            builder: (BuildContext scaffoldContext) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildTopBar(context, scaffoldContext),
                  const CategoryBar(),
                  const Expanded(child: ToolGrid()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建主页顶部栏。
  ///
  /// [scaffoldContext] 必须来自 Scaffold 后代 Builder，供菜单按钮打开抽屉。
  Widget _buildTopBar(BuildContext context, BuildContext scaffoldContext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: '打开侧边栏',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          ),
          const SizedBox(width: 4),
          const Expanded(child: _AnimatedHomeTitle()),
          IconButton(
            tooltip: '搜索功能',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppRoutes.search),
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
    // 品牌文字先停留 1.5 秒，再开始收缩和淡出动画。
    _startTimer = Timer(const Duration(milliseconds: 1500), () {
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  
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
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w700,
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
      width: 5,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
