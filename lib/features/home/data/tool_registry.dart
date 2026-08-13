/// 工具注册表。
///
/// 集中维护主页网格中展示的全部工具。
/// 后期新增功能时，只需在此列表中追加一个 [ToolItem]，
/// 并在路由配置（app_router.dart）中注册对应页面即可，无需改动页面逻辑。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tool_category.dart';
import '../models/tool_item.dart';

/// 提供全部工具列表的 Riverpod Provider。
///
/// 采用 Provider 而不是常量，便于后期接入远程配置 / 动态下发工具列表。
final toolRegistryProvider = Provider<List<ToolItem>>((ref) {
  return const <ToolItem>[
    // -------------------------------------------------------------------------
    // 内容展示类
    // -------------------------------------------------------------------------
    ToolItem(
      id: 'article',
      name: '文章内容',
      icon: Icons.article_rounded,
      category: ToolCategory.content,
      routePath: AppRoutes.articleList,
      accentColor: Color(0xFF3B6CF6),
    ),

    // -------------------------------------------------------------------------
    // 网络类
    // -------------------------------------------------------------------------
    ToolItem(
      id: 'network',
      name: '网络信息',
      icon: Icons.network_check_rounded,
      category: ToolCategory.network,
      routePath: AppRoutes.network,
      accentColor: Color(0xFF00A87E),
    ),

    // -------------------------------------------------------------------------
    // 预留：后续新增工具在此追加。
    // 示例（需同步创建对应页面与路由）：
    // ToolItem(
    //   id: 'image',
    //   name: '图片工具',
    //   icon: Icons.image_rounded,
    //   category: ToolCategory.content,
    //   routePath: '/image',
    //   accentColor: Color(0xFF00A87E),
    // ),
    // -------------------------------------------------------------------------
  ];
});

/// 路由路径常量（集中管理，避免页面与路由字符串散落各处）。
abstract final class AppRoutes {
  /// 主页（工具盒）。
  static const String home = '/';

  /// 文章内容展示页。
  static const String articleList = '/article';

  /// 全局设置页。
  static const String settings = '/settings';

  /// 关于 App 页。
  static const String about = '/about';

  /// 软件更新页。
  static const String update = '/update';

  /// 网络信息模块页。
  static const String network = '/network';

  /// 网速测试页（内嵌网页）。
  static const String speedTest = '/network/speed_test';
}
