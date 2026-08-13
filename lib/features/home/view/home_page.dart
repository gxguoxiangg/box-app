/// 主页（工具盒主界面）。
///
/// 布局自上而下：
/// 1. 顶部栏：左侧菜单按钮 + 应用名 + 搜索框（搜索功能预留）；
/// 2. 分类导航栏：对下方工具按钮进行筛选；
/// 3. 工具按钮网格：每个按钮跳转对应功能页面。
///
/// 侧边栏（Drawer）包含「关于 App」「软件更新」「全局设置」入口。
///
/// 本页面为纯 View，不持有业务状态；状态均由
/// [homeViewModelProvider] 统一管理（MVVM 的 View 层）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import 'widgets/category_bar.dart';
import 'widgets/tool_grid.dart';

/// 主页（工具盒）。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // 侧边栏：关于 App / 全局设置入口。
      // backgroundColor: Color(0xFFF5F6FA),
      drawer: const AppDrawer(),
      body: SafeArea(
        // 注意：必须用 Builder 包裹，使下方 context 成为 Scaffold 的「后代」，
        // 否则 Scaffold.of(context) 无法向上找到祖先 Scaffold，点击菜单按钮无效果。
        child: Builder(
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // -----------------------------------------------------------------
                // 顶部栏：菜单按钮 + 应用名 + 搜索框
                // -----------------------------------------------------------------
                _buildTopBar(context),

                // -----------------------------------------------------------------
                // 分类导航栏：筛选工具
                // -----------------------------------------------------------------
                const CategoryBar(),

                // -----------------------------------------------------------------
                // 工具按钮网格
                // -----------------------------------------------------------------
                const Expanded(child: ToolGrid()),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建顶部栏。
  ///
  /// [context] 必须是 Scaffold 的后代 context（由外层 Builder 提供），
  /// 这样才能通过 `Scaffold.of(context)` 打开抽屉。
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: <Widget>[
          // 左侧菜单按钮：打开侧边栏。
          IconButton(
            // tooltip: '打开侧边栏',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 4),
          // 应用名称（文本展示）。
          Text(
            AppConstants.appName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // 搜索框（预留功能：后续接入全局搜索）。
          const _SearchField(),
        ],
      ),
    );
  }
}

/// 顶部搜索框。
///
/// 目前为占位实现，仅做展示；后期迭代时接入真实搜索逻辑
/// （可参考 article 模块的搜索交互）。
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: TextField(
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
