/// 功能搜索页。
///
/// 搜索对象是主页工具注册表中的功能模块名称，采用连续字符串匹配。
/// 输入框每发生一次变化就立即刷新结果，不需要点击确认按钮。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/tool_item.dart';
import '../viewmodel/home_viewmodel.dart';

/// 工具功能搜索页。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  late final ToolSearchController _searchNotifier;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _searchNotifier = ref.read(toolSearchControllerProvider.notifier);
  }

  @override
  void dispose() {
    // Riverpod 不允许在卸载时同步通知监听者，延至当前帧结束再清空。
    Future<void>.microtask(() => _searchNotifier.setQuery(''));
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ToolItem> tools = ref.watch(filteredToolSearchProvider);
    final String query = ref.watch(toolSearchControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (String value) =>
              ref.read(toolSearchControllerProvider.notifier).setQuery(value),
          decoration: InputDecoration(
            hintText: '搜索功能',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: '清空搜索',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _controller.clear();
                      ref
                          .read(toolSearchControllerProvider.notifier)
                          .setQuery('');
                    },
                  ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '返回',
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _searchNotifier.setQuery('');
              context.pop();
            },
          ),
        ],
      ),
      body: query.trim().isNotEmpty && tools.isEmpty
          ? const Center(
              child: Opacity(
                opacity: 0.35,
                child: Text(
                  '空',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tools.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final ToolItem tool = tools[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tool.accentColor.withValues(alpha: 0.12),
                      foregroundColor: tool.accentColor,
                      child: Icon(tool.icon),
                    ),
                    title: Text(
                      tool.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(tool.routePath),
                  ),
                );
              },
            ),
    );
  }
}
