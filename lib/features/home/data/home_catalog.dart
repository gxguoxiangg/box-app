/// 主页设计稿中的全部工具目录。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_catalog_item.dart';

/// 当前六项只提供展示；后续实现功能时填入路由即可启用点击跳转。
final homeCatalogProvider = Provider<List<HomeCatalogItem>>(
  (ref) => homeCatalogItems,
);

/// 六项尚未接入功能页的工具。
const List<HomeCatalogItem> homeCatalogItems = <HomeCatalogItem>[
  HomeCatalogItem(
    id: 'prometheus',
    name: '普罗米修斯',
    description: '状态监控 / 带宽监控',
    icon: Icons.monitor_heart_outlined,
  ),
  HomeCatalogItem(
    id: 'network_calculator',
    name: '网络计算器',
    description: '子网掩码 / 带宽 / POE功耗等',
    icon: Icons.calculate_outlined,
  ),
  HomeCatalogItem(
    id: 'hash',
    name: 'Hash',
    description: 'MD5 / SHA256 / Base64 / URL编码',
    icon: Icons.lock_reset_rounded,
  ),
  HomeCatalogItem(
    id: 'ping',
    name: 'Ping',
    description: 'Ping测试',
    icon: Icons.network_ping_rounded,
  ),
  HomeCatalogItem(
    id: 'nmap',
    name: 'NMAP',
    description: '端口扫描',
    icon: Icons.track_changes_outlined,
  ),
  HomeCatalogItem(
    id: 'ip',
    name: 'IP',
    description: '公网IP查询',
    icon: Icons.language_rounded,
  ),
];

/// 后期扩展：完成工具页面后，在 AppRoutes 注册路径，并为对应条目填入 routePath。
