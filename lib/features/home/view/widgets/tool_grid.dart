/// 主页中部的「工具按钮」网格。
///
/// 每个工具对应一个带图标 + 名称的按钮，点击后通过 go_router
/// 跳转到对应的功能页面。按钮列表由 [homeViewModelProvider] 提供
/// （已按当前分类筛选）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/tool_item.dart';
import '../../viewmodel/home_viewmodel.dart';

/// 工具网格组件。
class ToolGrid extends ConsumerWidget {
  const ToolGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 订阅当前分类筛选后的工具列表。
    final List<ToolItem> tools = ref.watch(homeViewModelProvider).filteredTools;

    // 当前分类下暂无工具时，展示空态提示。
    if (tools.isEmpty) {
      return const Center(
        child: Text(
          '该分类下暂无功能',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      // 列数自适应：手机 3 列，宽屏（平板/桌面）更多列。
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // 按钮高宽比（图标 + 文字）。
        childAspectRatio: 1.1,
      ),
      itemCount: tools.length,
      itemBuilder: (BuildContext context, int index) {
        return _ToolButton(item: tools[index]);
      },
    );
  }
}

/// 单个工具按钮（图标 + 名称）。
class _ToolButton extends StatelessWidget {
  final ToolItem item;

  const _ToolButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // 通过 go_router 跳转到对应功能页面。
          context.push(item.routePath);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 图标（带淡色圆底衬托）
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.accentColor, size: 28),
            ),
            const SizedBox(height: 10),
            // 功能名称：使用加粗黑色，与分类导航栏的灰色文字形成层次。
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
