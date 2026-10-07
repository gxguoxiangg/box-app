/// 主页全部工具列表。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/busybox_palette.dart';
import '../../../../shared/widgets/busybox_card.dart';

import '../../data/home_catalog.dart';
import '../../models/home_catalog_item.dart';

/// 参照设计稿显示六项工具，未配置路由时保持展示状态。
class HomeAllTools extends ConsumerWidget {
  /// 创建全部工具区块。
  const HomeAllTools({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BusyBoxPalette palette = BusyBoxPalette.of(context);
    final List<HomeCatalogItem> items = ref.watch(homeCatalogProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '全部工具',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                '共 ${items.length} 项',
                style: TextStyle(
                  color: palette.subtle,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: <Widget>[
            for (int index = 0; index < items.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(height: 10),
              BusyBoxEntrance(
                order: index,
                child: _CatalogRow(item: items[index], palette: palette),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CatalogRow extends StatelessWidget {
  final HomeCatalogItem item;
  final BusyBoxPalette palette;

  const _CatalogRow({required this.item, required this.palette});

  @override
  Widget build(BuildContext context) {
    final String? routePath = item.routePath;
    return BusyBoxCard(
      radius: 16,
      key: ValueKey<String>('all-tool-${item.id}'),
      onTap: routePath == null ? null : () => context.push(routePath),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.inset,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Icon(item.icon, size: 20, color: palette.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18, color: palette.subtle),
          ],
        ),
      ),
    );
  }
}
