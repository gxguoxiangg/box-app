/// 应用路由配置（基于 go_router）。
///
/// 采用声明式路由，支持路径跳转与浏览器深链（Web 端）。
///
/// 新增功能页面的流程：
/// 1. 在 [AppRoutes]（features/home/data/tool_registry.dart）中定义路径常量；
/// 2. 在 [appRouter] 中注册对应 `GoRoute`；
/// 3. 在工具注册表（toolRegistryProvider）中登记工具按钮。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/view/about_page.dart';
import '../../features/article/view/article_list_page.dart';
import '../../features/home/data/tool_registry.dart';
import '../../features/home/view/home_page.dart';
import '../../features/network/view/network_page.dart';
import '../../features/network/view/speed_test_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/update/view/update_page.dart';

/// 全局路由 Provider。
///
/// 返回全局单例 [appRouter]（go_router 建议全局只创建一次）。
/// 使用 Provider 封装便于后期按需构建（例如登录态变化时重建路由表）。
final appRouterProvider = Provider<GoRouter>((ref) => appRouter);

/// go_router 全局单例实例。
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: <RouteBase>[
    // -------------------------------------------------------------------------
    // 主页（工具盒）
    // -------------------------------------------------------------------------
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),

    // -------------------------------------------------------------------------
    // 文章内容展示页
    // -------------------------------------------------------------------------
    GoRoute(
      path: AppRoutes.articleList,
      builder: (context, state) => const ArticleListPage(),
    ),

    // -------------------------------------------------------------------------
    // 全局设置页
    // -------------------------------------------------------------------------
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),

    // -------------------------------------------------------------------------
    // 关于 App 页
    // -------------------------------------------------------------------------
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutPage(),
    ),

    // -------------------------------------------------------------------------
    // 软件更新页（功能待定）
    // -------------------------------------------------------------------------
    GoRoute(
      path: AppRoutes.update,
      builder: (context, state) => const UpdatePage(),
    ),

    // -------------------------------------------------------------------------
    // 网络信息模块
    // -------------------------------------------------------------------------
    GoRoute(
      path: AppRoutes.network,
      builder: (context, state) => const NetworkPage(),
    ),

    // -------------------------------------------------------------------------
    // 网速测试页（内嵌网页）
    // -------------------------------------------------------------------------
    GoRoute(
      path: AppRoutes.speedTest,
      builder: (context, state) => const SpeedTestPage(),
    ),
  ],
);
