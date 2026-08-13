/// 软件更新页。
///
/// 当前为**占位实现**，仅搭建页面框架，更新功能待定开发。
/// 后期可在此接入版本检查、下载安装等逻辑（可结合 Riverpod 管理更新状态）。
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// 软件更新页。
class UpdatePage extends StatelessWidget {
  const UpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('软件更新'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 更新图标
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_alt_rounded,
                size: 44,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),

            // 当前版本
            Text(
              '当前版本 v${AppConstants.appVersion}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // 占位提示
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                '更新功能开发中，敬请期待',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 28),

            // 检查更新按钮（占位，点击仅提示）
            FilledButton.icon(
              onPressed: () {
                // 功能待定：暂以提示代替真实更新检查。
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('功能开发中，敬请期待')),
                );
              },
              icon: const Icon(Icons.update_rounded, size: 18),
              label: const Text('检查更新'),
            ),
          ],
        ),
      ),
    );
  }
}
