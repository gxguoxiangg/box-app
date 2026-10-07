/// 主页「全部工具」列表中的条目。
library;

import 'package:flutter/material.dart';

/// 未实现的工具可以先不指定路由；后续实现后填写 [routePath] 即可跳转。
class HomeCatalogItem {
  /// 稳定标识，用于列表 Key 与后期功能接入。
  final String id;

  /// 工具名称。
  final String name;

  /// 一行功能描述。
  final String description;

  /// 工具图标。
  final IconData icon;

  /// 已实现工具的路由路径；null 表示仅展示。
  final String? routePath;

  /// 创建一个主页目录条目。
  const HomeCatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.routePath,
  });
}
