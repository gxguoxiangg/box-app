/// 工具盒主页。
///
/// 顶部栏包含菜单、首次进入动画标题和搜索入口；下方为分类导航与功能网格。
/// 页面只负责布局和路由，功能数据由 HomeViewModel 提供。
library;

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
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
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
/// 动画严格按需求分段执行：GuoXiang 先收缩成两个平行黑点并消失，
/// LazyBox 随后渐隐，最后显示“主页”。组件每次重新创建时都会重新播放一次。
class _AnimatedHomeTitle extends StatefulWidget {
  const _AnimatedHomeTitle();

  @override
  State<_AnimatedHomeTitle> createState() => _AnimatedHomeTitleState();
}

class _AnimatedHomeTitleState extends State<_AnimatedHomeTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // ..forward();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
      _controller.forward();
      }
    });
  }

  @override
  void dispose() {
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
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          Transform.scale(
                            alignment: Alignment.centerLeft,
                            scaleX: 1 - 0.88 * guoShrinkProgress,
                            child: Opacity(
                              opacity: 1 - guoDotsProgress,
                              child: Text(
                                'GuoXiang',
                                style: TextStyle(
                                  color: titleColor,
                                  fontFamily: 'sans-serif',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: guoDotsProgress * (1 - lazyProgress),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _BlackDot(),
                                SizedBox(width: 4),
                                _BlackDot(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: 1 - lazyProgress,
                      child: Text(
                        ' LazyBox',
                        style: TextStyle(
                          color: titleColor,
                          // fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
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

/// GuoXiang 收缩动画的两个平行黑点。
class _BlackDot extends StatelessWidget {
  const _BlackDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 5,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      ),
    );
  }
}
