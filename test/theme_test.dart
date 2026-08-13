/// 主题（深色模式）控制器单元测试。
///
/// 验证：
/// - 默认主题为明亮模式；
/// - 切换后为深色模式；
/// - 选择被持久化到 shared_preferences。
library;

import 'package:demo1/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('默认主题为明亮模式，切换后为深色模式并持久化', () async {
    // 使用内存版 shared_preferences，避免真实插件通道。
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    // 首次读取：默认明亮模式（build 为异步，需等待 future 完成）。
    expect(await container.read(themeControllerProvider.future), ThemeMode.light);

    // 切换为深色模式。
    await container.read(themeControllerProvider.notifier).setDarkMode(dark: true);
    expect(await container.read(themeControllerProvider.future), ThemeMode.dark);

    // 校验持久化内容。
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeController.prefsKey), 'dark');

    // 切回明亮模式并校验持久化更新。
    await container.read(themeControllerProvider.notifier).setDarkMode(dark: false);
    expect(await container.read(themeControllerProvider.future), ThemeMode.light);
    expect(prefs.getString(ThemeController.prefsKey), 'light');
  });

  test('持久化值为深色时，重新加载仍为深色模式', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ThemeController.prefsKey: 'dark',
    });

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(themeControllerProvider.future), ThemeMode.dark);
  });
}
