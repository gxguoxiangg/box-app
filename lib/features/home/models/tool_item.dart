/// 单个「工具」的数据模型。
///
/// 主页网格中的每个按钮对应一个 [ToolItem]。
/// 点击按钮后，通过 [routePath] 跳转到对应功能页面。
library;

import 'package:flutter/material.dart';

import 'tool_category.dart';

/// 工具条目。
class ToolItem {
  // ---------------------------------------------------------------------------
  // 字段
  // ---------------------------------------------------------------------------

  /// 工具唯一标识（用于 key 与后期扩展，例如收藏、排序）。
  final String id;

  /// 功能名称（按钮下方显示的文字）。
  final String name;

  /// 功能图标（按钮上方显示的图标）。
  final IconData icon;

  /// 所属分类（用于分类导航栏筛选）。
  final ToolCategory category;

  /// 点击后跳转的路由路径（对应 go_router 中的路径）。
  final String routePath;

  /// 按钮强调色（用于图标着色 / 背景高亮）。
  final Color accentColor;

  // ---------------------------------------------------------------------------
  // 构造
  // ---------------------------------------------------------------------------

  const ToolItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.routePath,
    required this.accentColor,
  });
}
