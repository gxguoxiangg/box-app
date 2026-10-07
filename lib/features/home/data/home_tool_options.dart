/// 主页可固定工具的统一目录。
library;

import 'package:flutter/material.dart';

import 'home_catalog.dart';
import '../models/home_catalog_item.dart';
import 'tool_registry.dart';

/// 自定义页与主页共享的工具展示信息。
class HomeToolOption {
  /// 稳定标识。
  final String id;

  /// 名称。
  final String name;

  /// 简短说明。
  final String description;

  /// 图标。
  final IconData icon;

  /// 实际功能路由；为空时仅展示。
  final String? routePath;

  /// 创建工具选项。
  const HomeToolOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.routePath,
  });
}

/// 默认置顶的三个工具及目录里的六项工具。
///
/// 后期扩展：新工具先在此登记，然后在 AppRoutes 增加真实路由。
final List<HomeToolOption> homeToolOptions = <HomeToolOption>[
  const HomeToolOption(
    id: 'wiki',
    name: 'Wiki',
    description: '开发文档',
    icon: Icons.menu_book_outlined,
    routePath: AppRoutes.articleList,
  ),
  const HomeToolOption(
    id: 'speed',
    name: '测网速',
    description: '实时速率',
    icon: Icons.speed_rounded,
    routePath: AppRoutes.network,
  ),
  const HomeToolOption(
    id: 'smart',
    name: '神机',
    description: '智能搜索',
    icon: Icons.radar_rounded,
  ),
  for (final HomeCatalogItem item in homeCatalogItems)
    HomeToolOption(
      id: item.id,
      name: item.name,
      description: item.description,
      icon: item.icon,
      routePath: item.routePath,
    ),
];
