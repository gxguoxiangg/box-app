/// 应用侧边栏，参照 doc/ui/sidebar_page.html 的抽屉区域。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/busybox_palette.dart';
import '../../features/home/data/tool_registry.dart';

/// 主页侧边栏；设置和关于接入已有页面，统计暂时展示占位反馈。
class AppDrawer extends StatelessWidget {
  /// 创建抽屉。
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final BusyBoxPalette palette = BusyBoxPalette.of(context);
    return Drawer(
      width: 310,
      backgroundColor: palette.canvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'resource/images/atom.png',
                      width: 40,
                      height: 40,
                      semanticLabel: 'BusyBox 标志',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '更多',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭侧边栏',
                    icon: Icon(Icons.close, color: palette.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 0.5, thickness: 0.5, color: palette.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: <Widget>[
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: '设置',
                    subtitle: '通用偏好与主题',
                    palette: palette,
                    onTap: () => _navigate(context, AppRoutes.settings),
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_outlined,
                    title: '统计',
                    subtitle: '使用统计',
                    palette: palette,
                    onTap: () {
                      final ScaffoldMessengerState messenger =
                          ScaffoldMessenger.of(context);
                      Navigator.of(context).pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('统计功能待开发')),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    title: '关于APP',
                    subtitle: '版本信息',
                    palette: palette,
                    onTap: () => _navigate(context, AppRoutes.about),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    final GoRouter router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(route);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final BusyBoxPalette palette;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: palette.canvas,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.inset,
                border: Border.all(color: palette.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: palette.muted, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: palette.subtle),
          ],
        ),
      ),
    ),
  );
}
