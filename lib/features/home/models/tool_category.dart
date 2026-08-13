/// 工具分类枚举。
///
/// 用于主页顶部的「分类导航栏」对工具按钮进行筛选展示。
/// 后期新增分类时，在此追加枚举项，并在 [ToolItem] 中引用即可。
library;

import 'package:flutter/material.dart';

/// 工具分类。
enum ToolCategory {
  /// 「全部」：特殊分类，表示展示所有工具（不做过滤）。
  all(
    label: '全部',
    icon: Icons.grid_view_rounded,
  ),

  /// 内容展示类：与「文章内容展示」等功能相关。
  content(
    label: '文档类',
    icon: Icons.article_outlined,
  ),

  network(
    label: '网络类',
    icon: Icons.network_check_outlined,
  ),

  /// 系统工具类：预留分类，后续新增系统相关功能时使用。
  system(
    label: '系统类',
    icon: Icons.settings_outlined,
  ),

  other(
    label: '其他',
    icon: Icons.handyman_outlined,
  );


  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 分类显示名称。
  final String label;

  /// 分类图标（用于分类导航栏上的展示）。
  final IconData icon;

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const ToolCategory({required this.label, required this.icon});
}
