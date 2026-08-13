/// 主页（工具盒）ViewModel。
///
/// 职责：
/// - 维护「当前选中的工具分类」这一界面状态；
/// - 根据分类对工具列表进行筛选，向 View 层提供最终展示数据。
///
/// View 层通过 `ref.watch(homeViewModelProvider)` 订阅状态，
/// 通过 `ref.read(homeViewModelProvider.notifier)` 调用方法修改状态。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tool_registry.dart';
import '../models/tool_category.dart';
import '../models/tool_item.dart';

/// 主页状态。
class HomeState {
  /// 当前选中的分类（默认「全部」）。
  final ToolCategory selectedCategory;

  /// 所有工具（完整列表）。
  final List<ToolItem> allTools;

  const HomeState({
    this.selectedCategory = ToolCategory.all,
    this.allTools = const <ToolItem>[],
  });

  /// 根据当前分类过滤后的工具列表。
  ///
  /// 「全部」分类不做过滤；其余分类只保留属于该分类的工具。
  List<ToolItem> get filteredTools => selectedCategory == ToolCategory.all
      ? allTools
      : allTools.where((t) => t.category == selectedCategory).toList();
    
  /// 复制并修改部分字段（用于不可变状态更新）。
  HomeState copyWith({ToolCategory? selectedCategory, List<ToolItem>? allTools}) {
    return HomeState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      allTools: allTools ?? this.allTools,
    );
  }
}

/// 主页 ViewModel（Notifier 风格，Riverpod 3 推荐写法）。
///
/// 初始化时从 [toolRegistryProvider] 读取工具注册表，
/// 之后通过 [selectCategory] 切换分类并自动触发 UI 更新。
class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    // 从工具注册表初始化完整工具列表。
    final List<ToolItem> tools = ref.watch(toolRegistryProvider);
    return HomeState(allTools: tools);
  }

  /// 切换选中的分类（在分类导航栏点击时调用）。
  ///
  /// 同一分类重复点击时不做任何操作，避免无谓重建。
  void selectCategory(ToolCategory category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
  }
}

/// 主页 ViewModel 的 Provider。
///
/// View 层通过它读写主页状态；该 Provider 在无监听者时自动释放。
final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
