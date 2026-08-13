/// 主页顶部的「分类导航栏」。
///
/// 横向可滚动的分类标签（Chip），点击后切换主页工具列表的筛选分类。
/// 选中项高亮显示，数据由 [homeViewModelProvider] 驱动。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tool_category.dart';
import '../../viewmodel/home_viewmodel.dart';

/// 分类导航栏组件。
class CategoryBar extends ConsumerWidget {
  const CategoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 订阅当前选中的分类；分类变化时自动重建。
    final HomeState state = ref.watch(homeViewModelProvider);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        // 横向滚动。
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: ToolCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final ToolCategory category = ToolCategory.values[index];
          final bool isSelected = category == state.selectedCategory;
          return _CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () {
              // 通过 ViewModel 切换分类，触发列表刷新。
              ref.read(homeViewModelProvider.notifier).selectCategory(category);
            },
          );
        },
      ),
    );
  }
}

/// 单个分类标签。
class _CategoryChip extends StatelessWidget {
  final ToolCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : const Color(0xFFE5E7EB),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              category.icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
