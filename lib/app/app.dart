/// 应用根组件。
///
/// 通过 `MaterialApp.router` 接入 go_router，
/// 并统一设置主题（见 [AppTheme]）。
///
/// 后期如需在根组件挂载全局能力（如初始化、本地化、生命周期监听），
/// 可在此统一扩展。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router/app_router.dart';

/// 应用根组件。
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取全局路由实例。
    final router = ref.watch(appRouterProvider);
    // 订阅主题模式：持久化值加载完成前以明亮模式兜底，避免闪屏。
    final ThemeMode themeMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.light;

    return MaterialApp.router(
      title: '工具盒',
      debugShowCheckedModeBanner: false,
      // 通过 themeMode 在明/暗主题间切换（由「全局设置 → 深色模式」控制）。
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
