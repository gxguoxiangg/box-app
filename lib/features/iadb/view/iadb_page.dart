/// 神机资产搜索界面。后期扩展：筛选或排序仅在后端支持后增加。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/busybox_palette.dart';
import '../../../core/theme/page_header_typography.dart';
import '../../../core/network/api_client.dart';
import '../models/iadb_models.dart';
import 'iadb_asset_card.dart';
import '../viewmodel/iadb_viewmodel.dart';

/// 独立登录及资产检索入口。
class IadbPage extends ConsumerStatefulWidget {
  /// 创建神机页。
  const IadbPage({super.key});
  @override
  ConsumerState<IadbPage> createState() => _IadbPageState();
}

class _IadbPageState extends ConsumerState<IadbPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _query = TextEditingController();
  bool _records = false;
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _query.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Text(message),
        ),
      );
    }
  }

  Future<void> _login() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      _message('请输入账号和密码');
      return;
    }
    await ref
        .read(iadbSessionProvider.notifier)
        .login(_username.text, _password.text);
    if (mounted && ref.read(iadbSessionProvider).value != null) {
      _password.clear();
    }
  }

  Future<void> _logout() async {
    _query.clear();
    try {
      await ref.read(iadbSessionProvider.notifier).logout();
    } catch (_) {
      _message('已清除本地登录，服务端退出未成功，请稍后重新登录并退出');
    }
  }

  void _search() {
    FocusScope.of(context).unfocus();
    ref.read(iadbSearchProvider.notifier).search(_query.text);
  }

  @override
  Widget build(BuildContext context) {
    final palette = BusyBoxPalette.of(context);
    final auth = ref.watch(iadbSessionProvider);
    final search = ref.watch(iadbSearchProvider);
    ref.listen(iadbSessionProvider, (previous, next) {
      if (previous?.value != null && next.value == null) _query.clear();
    });
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFFBF9F8)
          : palette.page,
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: '返回',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFFBF9F8)
            : palette.page,
        foregroundColor: palette.ink,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 56,
        titleSpacing: 4,
        centerTitle: false,
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('神机', style: PageHeaderTypography.title),
            Text(
              'BusyBox 工具魔盒',
              style: PageHeaderTypography.subtitle.copyWith(
                color: palette.muted,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: '神机账号',
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(auth.value?.username ?? '尚未登录'),
              ),
              if (auth.value != null)
                const PopupMenuItem(value: 'logout', child: Text('退出神机账号')),
            ],
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: palette.accent,
              child: Icon(
                Icons.person_outline,
                size: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? palette.page
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: auth.value == null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 28),
                      Icon(
                        Icons.radar_rounded,
                        size: 48,
                        color: palette.accent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '登录神机',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '请使用神机账户登录',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _username,
                        enabled: !auth.isLoading,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(labelText: '账号'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _password,
                        enabled: !auth.isLoading,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        onSubmitted: (_) {
                          if (!auth.isLoading) _login();
                        },
                        decoration: const InputDecoration(labelText: '密码'),
                      ),
                      if (auth.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error(auth.error),
                            style: TextStyle(color: palette.error),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _login,
                        child: Text(auth.isLoading ? '登录中…' : '登录'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: TextField(
                          controller: _query,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            hintText: '搜索 IP、MAC、人员、部门、设备型号…',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: palette.subtle,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: palette.accent,
                                width: 2,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: palette.accent,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: palette.inset,
                            prefixIcon: Icon(
                              Icons.auto_awesome,
                              color: palette.accent,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: '清空搜索',
                                  onPressed: () {
                                    _query.clear();
                                    ref
                                        .read(iadbSearchProvider.notifier)
                                        .clear();
                                  },
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 18,
                                  ),
                                ),
                                IconButton(
                                  tooltip: '搜索资产',
                                  onPressed: _search,
                                  icon: const Icon(Icons.search),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: search.result.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_error(error)),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () => ref
                                        .read(iadbSearchProvider.notifier)
                                        .search(search.query),
                                    child: const Text('重试'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          data: (result) => result == null
                              ? const Center(child: Text('输入关键词开始检索资产'))
                              : _results(result, search),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _results(IadbResults result, IadbSearchState search) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          children: [
            Text(
              _records ? '命中记录' : '命中资产',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: BusyBoxPalette.of(
                  context,
                ).accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_records ? result.recordCount : result.assetCount} 项',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const Spacer(),
            PopupMenuButton<bool>(
              tooltip: '切换结果类型',
              onSelected: (value) => setState(() => _records = value),
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: false,
                  checked: !_records,
                  child: Text('资产 (${result.assetCount})'),
                ),
                CheckedPopupMenuItem(
                  value: true,
                  checked: _records,
                  child: Text('命中记录 (${result.recordCount})'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _records ? '资产' : '命中记录 (${result.recordCount})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Icon(Icons.expand_more, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: (_records ? result.records.isEmpty : result.assets.isEmpty)
            ? const Center(child: Text('本页暂无结果'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _records
                    ? result.records.length
                    : result.assets.length,
                itemBuilder: (context, index) {
                  if (!_records) return _assetCard(result.assets[index]);
                  final record = result.records[index];
                  return Card(
                    child: ListTile(
                      title: Text(iadbText(record['table'])),
                      subtitle: Text(
                        '记录 #${iadbText(iadbObject(record['record'])['id'])}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _details('命中记录', record),
                    ),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              '共 ${result.assetCount} 项资产 · ${result.recordCount} 条记录 · ${search.elapsedMs}ms',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: BusyBoxPalette.of(context).subtle,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: result.offset > 0
                      ? () => ref
                            .read(iadbSearchProvider.notifier)
                            .search(
                              search.query,
                              offset: (result.offset - result.limit).clamp(
                                0,
                                1000000,
                              ),
                            )
                      : null,
                  child: const Text('上一页'),
                ),
                Text('第 ${result.offset ~/ result.limit + 1} 页'),
                TextButton(
                  onPressed:
                      result.hasNext && result.offset + result.limit <= 1000000
                      ? () => ref
                            .read(iadbSearchProvider.notifier)
                            .search(
                              search.query,
                              offset: result.offset + result.limit,
                            )
                      : null,
                  child: const Text('下一页'),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _assetCard(IadbAsset item) => IadbAssetCard(
    asset: item,
    onDetails: () => _details(item.title, item.context),
    onCopy: (label, value) async {
      try {
        await Clipboard.setData(ClipboardData(text: value));
        _message('已复制 $label');
      } catch (_) {
        _message('复制失败，请重试');
      }
    },
  );
  void _details(String title, Map<String, Object?> data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            ListTile(
              title: Text(title),
              trailing: IconButton(
                tooltip: '关闭详情',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel_outlined, size: 18),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _fields(data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _error(Object? error) =>
    error is ApiException ? error.message : '操作失败，请稍后重试';

// 原始关联字段逐层展示，未识别的新字段也保留，避免接口扩展后丢失信息。
List<Widget> _fields(Map<String, Object?> data) => data.entries.map((entry) {
  final label = _labels[entry.key] ?? entry.key;
  final value = entry.value;
  if (value is Map<String, Object?>) {
    return ExpansionTile(title: Text(label), children: _fields(value));
  }
  if (value is List) {
    return ExpansionTile(
      title: Text('$label (${value.length})'),
      children: [
        for (var index = 0; index < value.length; index++)
          if (value[index] is Map<String, Object?>)
            ExpansionTile(
              title: Text('${index + 1}'),
              children: _fields(iadbObject(value[index])),
            )
          else
            ListTile(title: SelectableText(iadbText(value[index]))),
      ],
    );
  }
  return ListTile(
    dense: true,
    title: Text(label),
    subtitle: SelectableText(iadbText(value)),
  );
}).toList();
const _labels = {
  'asset': '资产',
  'owner': '负责人',
  'department': '部门',
  'owner_department': '负责人部门',
  'location': '位置',
  'interfaces': '网卡接口',
  'ip_addresses': 'IP 地址',
  'connections': '连接',
  'switch_ports': '交换机端口',
  'relations': '关联关系',
  'discovered_devices': '发现设备',
  'history': '历史记录',
  'matched_by': '命中来源',
  'name': '名称',
  'asset_type': '资产类型',
  'asset_code': '资产编号',
  'vendor': '厂商',
  'model': '型号',
  'serial_number': '序列号',
  'status': '状态',
  'description': '描述',
  'created_at': '创建时间',
  'updated_at': '更新时间',
  'interface_name': '接口名称',
  'mac_address': 'MAC 地址',
  'ip_address': 'IP 地址',
  'gateway': '网关',
  'table': '来源表',
  'record': '记录',
  'attributes': '附加属性',
};
