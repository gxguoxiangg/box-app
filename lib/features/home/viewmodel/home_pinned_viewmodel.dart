/// 常用工具配置：最多六项，本地保存，主页与自定义页实时共享。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/home_tool_options.dart';

/// 初次安装时的常用工具顺序。
const List<String> defaultPinnedTools = <String>['wiki', 'speed', 'smart'];

/// 常用工具状态控制器。
class HomePinnedController extends AsyncNotifier<List<String>> {
  static const String _prefsKey = 'home_pinned_tools';
  static const int maxPinned = 6;

  @override
  Future<List<String>> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList(_prefsKey);
    if (saved == null) return defaultPinnedTools;
    final Set<String> validIds = homeToolOptions.map((item) => item.id).toSet();
    return saved.where(validIds.contains).toSet().take(maxPinned).toList();
  }

  /// 把工具加入常用区；已选或满额时不改变状态。
  Future<void> add(String id) async {
    final List<String> current = await future;
    if (current.contains(id) ||
        current.length >= maxPinned ||
        !homeToolOptions.any((item) => item.id == id)) {
      return;
    }
    await _save(<String>[...current, id]);
  }

  /// 从常用区移除工具。
  Future<void> remove(String id) async {
    final List<String> current = await future;
    if (!current.contains(id)) return;
    await _save(current.where((item) => item != id).toList());
  }

  Future<void> _save(List<String> ids) async {
    // 先更新 UI，再异步落盘；保存失败仍保持本次会话中的选择。
    state = AsyncData<List<String>>(ids);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids);
  }
}

/// 全局常用工具配置。
final homePinnedProvider =
    AsyncNotifierProvider<HomePinnedController, List<String>>(
      HomePinnedController.new,
    );

/// 全部工具区仅展示未固定项，与自定义页共享完整工具目录。
final unpinnedHomeToolsProvider = Provider<List<HomeToolOption>>((ref) {
  final pinned = ref.watch(homePinnedProvider).value ?? defaultPinnedTools;
  return homeToolOptions.where((item) => !pinned.contains(item.id)).toList();
});
