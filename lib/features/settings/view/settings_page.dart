/// 全局设置页。
///
/// 目前已实现：
/// - **外观 → 深色模式**：切换明亮 / 黑暗主题（状态由
///   [themeControllerProvider] 管理并持久化）。
///
/// 后期迭代可在此接入：语言、通知、缓存清理等。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_controller.dart';

/// 全局设置页。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 订阅当前主题模式（用于驱动开关状态）。
    final bool isDark =
        (ref.watch(themeControllerProvider).value ?? ThemeMode.light) ==
            ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('全局设置'),
      ),
      body: ListView(
        children: <Widget>[
          const _SectionHeader(title: '外观'),
          // 深色模式开关：切换主题模式并持久化。
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            subtitle: const Text('切换明亮 / 黑暗主题'),
            value: isDark,
            onChanged: (bool value) {
              ref
                  .read(themeControllerProvider.notifier)
                  .setDarkMode(dark: value);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // -------------------------------------------------------------------
          // 以下为预留设置项（功能待开发）。
          // -------------------------------------------------------------------
          const _SectionHeader(title: '通用'),
          const ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('语言'),
            subtitle: Text('简体中文（待开发）'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const ListTile(
            leading: Icon(Icons.cleaning_services_outlined),
            title: Text('清除缓存'),
            subtitle: Text('0.0 MB（待开发）'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ),
    );
  }
}

/// 设置分组标题。
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
