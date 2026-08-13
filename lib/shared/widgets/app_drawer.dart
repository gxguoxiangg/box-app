/// 应用侧边栏（Drawer）。
///
/// 内容：
/// - 顶部：应用 Logo / 名称 / 版本信息区；
/// - 选项列表（多个入口）：
///   1. 关于 App —— 跳转关于页（居中展示图标、名称、版本）；
///   2. 软件更新 —— 跳转更新页（功能待定）；
///   3. 全局设置 —— 跳转设置页。
///
/// 后期如需增加更多侧边栏入口，只需在 [_menuItems] 中追加一项即可。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/data/tool_registry.dart';

/// 侧边栏组件。
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// 侧边栏菜单项配置（集中维护，便于扩展）。
  static const List<_DrawerMenuItem> _menuItems = <_DrawerMenuItem>[
    // 关于 App
    _DrawerMenuItem(
      icon: Icons.info_outline_rounded,
      title: '关于 App',
      route: AppRoutes.about,
    ),
    // 软件更新
    _DrawerMenuItem(
      icon: Icons.system_update_alt_rounded,
      title: '软件更新',
      route: AppRoutes.update,
    ),
    // 全局设置
    _DrawerMenuItem(
      icon: Icons.settings_outlined,
      title: '全局设置',
      route: AppRoutes.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // -------------------------------------------------------------------
            // 顶部：应用信息展示区
            // -------------------------------------------------------------------
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Text(
                '更多',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700
                ),
              ),
            ),
            /*
              Row(
                children: <Widget>[
                  // 应用图标
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.widgets_rounded, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  // 应用名称 + 版本号
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'v${AppConstants.appVersion}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            */
            // const Divider(),

            // -------------------------------------------------------------------
            // 中部：功能入口选项列表
            // -------------------------------------------------------------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 0),
                children: <Widget>[
                  // 根据配置循环渲染菜单项。
                  for (final _DrawerMenuItem item in _menuItems)
                    ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _navigate(context, item.route),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 关闭抽屉并跳转到指定路由。
  void _navigate(BuildContext context, String route) {
    // 先关闭抽屉，再通过 go_router 跳转。
    Navigator.of(context).pop();
    context.push(route);
  }
}

/// 侧边栏菜单项配置类。
class _DrawerMenuItem {
  final IconData icon;
  final String title;
  final String route;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });
}
