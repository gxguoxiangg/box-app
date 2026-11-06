import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/busybox_palette.dart';
import '../../../core/theme/page_header_typography.dart';
import '../../home/data/tool_registry.dart';
import '../data/ping_repository.dart';
import '../models/ping_models.dart';
import '../viewmodel/ping_viewmodel.dart';
import 'ping_chart.dart';

/// Ping 输入页。后期扩展：参数增加时同步更新模型校验。
class PingPage extends ConsumerStatefulWidget {
  /// 创建输入页。
  const PingPage({super.key});
  @override
  ConsumerState<PingPage> createState() => _PingPageState();
}

class _PingPageState extends ConsumerState<PingPage> {
  final targets = [TextEditingController()];
  final bytes = TextEditingController(text: '64');
  final count = TextEditingController(text: '4');
  final timeout = TextEditingController(text: '1000');
  String? error;
  bool expanded = true;
  @override
  void dispose() {
    for (final c in [...targets, bytes, count, timeout]) {
      c.dispose();
    }
    super.dispose();
  }

  void start() {
    final config = PingConfig(
      List.unmodifiable(targets.map((c) => c.text.trim().toLowerCase())),
      bytes: int.tryParse(bytes.text) ?? 0,
      count: int.tryParse(count.text) ?? 0,
      timeoutMs: int.tryParse(timeout.text) ?? 0,
    );
    setState(() => error = config.error);
    if (error == null) context.push(AppRoutes.pingResult, extra: config);
  }

  @override
  Widget build(BuildContext context) {
    final p = BusyBoxPalette.of(context);
    final supported = ref.watch(pingTransportProvider).supported;
    return Scaffold(
      appBar: _bar(context),
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFFBF9F8)
          : p.page,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _card(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.sensors, size: 20, color: p.accent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '目标地址',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'ICMP 协议连通性探测',
                            style: TextStyle(fontSize: 12, color: p.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final t in ['223.5.5.5', '8.8.8.8', 'baidu.com'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ActionChip(
                            backgroundColor: p.inset,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            label: SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  t,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: p.ink,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () => targets.last.text = t,
                          ),
                        ),
                      ),
                  ],
                ),
                for (var i = 0; i < targets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      key: ValueKey('ping-target-$i'),
                      controller: targets[i],
                      autocorrect: false,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '输入IP地址或域名',
                        hintStyle: TextStyle(
                          color: p.subtle,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(Icons.alternate_email),
                        filled: true,
                        fillColor: p.inset,
                        suffixIcon: IconButton(
                          tooltip: i == 0 ? '清空目标' : '移除目标',
                          icon: Icon(
                            i == 0
                                ? Icons.cancel_outlined
                                : Icons.remove_circle_outline,
                          ),
                          onPressed: () {
                            if (i == 0) {
                              targets[i].clear();
                            } else {
                              setState(() => targets.removeAt(i).dispose());
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                CustomPaint(
                  painter: _DashedBorder(p.border),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: p.accent,
                      side: BorderSide.none,
                    ),
                    onPressed: targets.length >= 4
                        ? null
                        : () => setState(
                            () => targets.add(TextEditingController()),
                          ),
                    icon: const Icon(Icons.add),
                    label: const Text('添加测试目标'),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p.inset,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '参数设置',
                              style: TextStyle(fontSize: 12, color: p.muted),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => expanded = !expanded),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 24),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              expanded ? '精简模式 ⌃' : '展开参数 ⌄',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (expanded)
                        Row(
                          children: [
                            Expanded(child: _input(bytes, 'Bytes', '1–1472')),
                            const SizedBox(width: 8),
                            Expanded(child: _input(count, 'Count', '1–100')),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _input(timeout, '超时 ms', '100–10000'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error ?? '', style: TextStyle(color: p.error)),
                  ),
                if (!supported)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('暂仅支持 Android 真实 ICMP Ping'),
                  ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: supported ? start : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始 Ping 测试'),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '测试历史',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '共 ${ref.watch(pingHistoryProvider).value?.length ?? 0} 条',
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(pingHistoryRepositoryProvider).clear();
                    ref.invalidate(pingHistoryProvider);
                  } catch (_) {
                    if (context.mounted) _notice(context, '清除历史失败');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: p.muted,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 16),
                    SizedBox(width: 2),
                    Text('清空历史'),
                  ],
                ),
              ),
            ],
          ),
          ref
              .watch(pingHistoryProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('历史读取失败'),
                data: (records) {
                  if (records.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('暂无测试历史'),
                    );
                  }
                  return Column(
                    children: [
                      for (final record in records) _history(context, record),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String title, String hint) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: BusyBoxPalette.of(context).canvas,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: BusyBoxPalette.of(context).subtle,
              ),
            ),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.only(top: 4),
                hintText: hint,
                hintStyle: TextStyle(
                  color: BusyBoxPalette.of(context).subtle,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ],
        ),
      );
  Widget _history(BuildContext context, String record) {
    try {
      final decoded = jsonDecode(record);
      if (decoded is! Map<String, Object?> || decoded['report'] is! String) {
        return const SizedBox.shrink();
      }
      final palette = BusyBoxPalette.of(context);
      final time = DateTime.tryParse('${decoded['time']}')?.toLocal();
      final stamp = time == null ? '时间未知' : time.toString().split('.').first;
      final age = time == null ? null : DateTime.now().difference(time);
      final relative = age == null
          ? '时间未知'
          : age.inMinutes < 1
          ? '刚刚'
          : age.inMinutes < 60
          ? '${age.inMinutes}分钟前'
          : age.inHours < 24
          ? '${age.inHours}小时前'
          : '${age.inDays}天前';
      final items = decoded['targets'];
      if (items is! List || items.isEmpty) {
        return _card(context, Text('${decoded['report']}\n$stamp'));
      }
      return Column(
        children: [
          for (final item in items.whereType<Map<String, Object?>>())
            _card(
              context,
              Builder(
                builder: (context) {
                  final loss = (item['loss'] as num?)?.toDouble();
                  final color = loss == null
                      ? palette.subtle
                      : loss == 0
                      ? palette.success
                      : palette.error;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['target'] ?? '—'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              loss == null
                                  ? '无数据'
                                  : loss == 0
                                  ? '正常'
                                  : '丢包',
                              style: TextStyle(color: color, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$relative · ${decoded['bytes'] == null ? '' : "${decoded['bytes']} 字节 · "}${item['sent']} 次探测',
                        style: TextStyle(fontSize: 12, color: palette.subtle),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _historyMetric(
                              context,
                              '平均延迟',
                              '${PingTargetResult.number((item['average'] as num?)?.toDouble())} ms',
                              palette.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _historyMetric(
                              context,
                              '丢包率',
                              '${_percent(loss)}%',
                              color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        stamp,
                        style: TextStyle(fontSize: 12, color: palette.subtle),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

/// 实时结果页；离开或进入后台停止本次任务。
class PingResultPage extends ConsumerStatefulWidget {
  /// 传入已校验配置；深链无配置时显示返回提示。
  const PingResultPage({super.key, this.config});

  /// 本次参数。
  final PingConfig? config;
  @override
  ConsumerState<PingResultPage> createState() => _PingResultPageState();
}

class _PingResultPageState extends ConsumerState<PingResultPage>
    with WidgetsBindingObserver {
  final _reportKey = GlobalKey();
  bool _exporting = false;

  Future<void> _exportReport(bool share) async {
    if (_exporting || ref.read(pingRunProvider).running) return;
    setState(() => _exporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final render = _reportKey.currentContext?.findRenderObject();
      if (render is! RenderRepaintBoundary) throw StateError('报告未就绪');
      final ratio = (8192 / render.size.longestSide).clamp(0.1, 2.0);
      final image = await render.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('图片生成失败');
      final bytes = data.buffer.asUint8List();
      final name = 'BusyBox-Ping-${DateTime.now().millisecondsSinceEpoch}';
      if (!mounted) return;
      if (share) {
        final box = context.findRenderObject();
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(bytes, mimeType: 'image/png', name: '$name.png'),
            ],
            fileNameOverrides: ['$name.png'],
            title: 'Ping 测试报告',
            sharePositionOrigin: box is RenderBox
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          ),
        );
      } else {
        final saved = await FileSaver.instance.saveAs(
          name: name,
          bytes: bytes,
          fileExtension: 'png',
          mimeType: MimeType.png,
        );
        if (mounted && saved != null) _notice(context, '报告图片已保存');
      }
    } catch (_) {
      if (mounted) _notice(context, '图片导出失败，请重试');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _showExportSheet() async {
    final p = BusyBoxPalette.of(context);
    final choice = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: p.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '导出或分享测试报告',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: Icon(Icons.close, size: 20, color: p.muted),
                  ),
                ],
              ),
              Divider(color: p.border, height: 16, thickness: 1),
              for (final option in [
                (
                  true,
                  '微信',
                  '打开系统分享面板，选择微信或其他应用',
                  Icons.chat_bubble_outline,
                  const Color(0xFF07C160),
                ),
                (
                  false,
                  '保存图片',
                  '选择位置保存完整 PNG 报告',
                  Icons.image_outlined,
                  p.accent,
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: p.inset,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(sheetContext, option.$1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: option.$5.withValues(alpha: .1),
                              child: Icon(option.$4, color: option.$5),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.$2,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    option.$3,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: p.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: p.subtle),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: p.inset,
                  foregroundColor: p.ink,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('取消'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted) await _exportReport(choice);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = widget.config;
      if (mounted && config != null) {
        ref.read(pingRunProvider.notifier).start(config);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(pingRunProvider.notifier).stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pingRunProvider);
    final p = BusyBoxPalette.of(context);
    return Scaffold(
      appBar: _bar(context),
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFFBF9F8)
          : p.page,
      body: widget.config == null
          ? const Center(child: Text('请从 Ping 首页设置目标后开始测试'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: _reportKey,
                child: ColoredBox(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFFBF9F8)
                      : p.page,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.notice != null)
                        Text(
                          state.notice ?? '',
                          style: TextStyle(color: p.error),
                        ),
                      for (final target in state.results) ...[
                        _card(
                          context,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      state.running && !target.finished
                                          ? '● 探测进行中 · ${target.sent}/${widget.config?.count ?? 0}'
                                          : target.loss == 0
                                          ? '● 测试完成 · 链路正常'
                                          : '● 探测结束 · ${target.loss == 100 ? '全部丢包' : '存在丢包'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: state.running
                                            ? p.accent
                                            : target.loss == 0
                                            ? p.success
                                            : p.error,
                                      ),
                                    ),
                                  ),
                                  if (state.running && !target.finished)
                                    Text(
                                      '● RTT RUNNING',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: p.accent,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                target.target,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (state.running && !target.finished) ...[
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value:
                                      target.sent / (widget.config?.count ?? 1),
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(4),
                                  color: p.accent,
                                  backgroundColor: p.inset,
                                ),
                              ],
                              if (!state.running &&
                                  target.samples.isNotEmpty &&
                                  target.samples.last.error != null)
                                Text(
                                  target.samples.last.error ?? '',
                                  style: TextStyle(color: p.error),
                                ),
                            ],
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, c) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final field in [
                                ('丢包率 (Loss)', '${_percent(target.loss)}%'),
                                (
                                  '平均延迟 (Avg)',
                                  '${PingTargetResult.number(target.average)} ms',
                                ),
                                ('发送包数 (Tx)', '${target.sent} pkts'),
                                ('接收包数 (Rx)', '${target.received} pkts'),
                              ])
                                SizedBox(
                                  width: (c.maxWidth - 8) / 2,
                                  child: _card(
                                    context,
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          field.$1,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: p.muted,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: field.$2.split(' ').first,
                                              ),
                                              if (field.$2.contains(' '))
                                                TextSpan(
                                                  text:
                                                      ' ${field.$2.split(' ').last}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600,
                                            color: field.$1.startsWith('丢包')
                                                ? (target.loss == null
                                                      ? p.subtle
                                                      : target.loss == 0
                                                      ? p.success
                                                      : p.error)
                                                : field.$1.startsWith('平均')
                                                ? p.accent
                                                : p.ink,
                                          ),
                                        ),
                                        if (state.running) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            field.$1.startsWith('丢包')
                                                ? (target.sent == 0
                                                      ? '等待回包'
                                                      : target.loss == 0
                                                      ? '未出现超时回包'
                                                      : '存在丢包')
                                                : field.$1.startsWith('平均')
                                                ? '实时统计（前 ${target.sent} 包）'
                                                : field.$1.startsWith('发送')
                                                ? '间隔至少 1000ms'
                                                : (target.sent > 0 &&
                                                          target.received ==
                                                              target.sent
                                                      ? '全部及时应答'
                                                      : '已收到 ${target.received} 包'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: p.muted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: p.inset,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final metric in [
                                ('最小延迟 (Min)', target.minimum),
                                ('最大延迟 (Max)', target.maximum),
                                ('延迟抖动 (Mdev)', target.mdev),
                              ])
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        metric.$1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: p.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: PingTargetResult.number(
                                                metric.$2,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' ms',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: p.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _card(
                          context,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PingChart(
                                result: target,
                                running: state.running && !target.finished,
                                count: widget.config?.count ?? 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                      Row(
                        children:
                            [
                                  if (state.running)
                                    OutlinedButton(
                                      onPressed: () => ref
                                          .read(pingRunProvider.notifier)
                                          .stop(),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: p.error.withValues(
                                          alpha: .08,
                                        ),
                                        foregroundColor: p.error,
                                        minimumSize: const Size(0, 48),
                                        side: BorderSide(
                                          color: p.error.withValues(alpha: .25),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('终止本次探测', maxLines: 1),
                                      ),
                                    ),
                                  if (!state.running)
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: p.inset,
                                        foregroundColor: p.ink,
                                        minimumSize: const Size(0, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: state.running || _exporting
                                          ? null
                                          : () {
                                              final config = widget.config;
                                              if (config != null) {
                                                ref
                                                    .read(
                                                      pingRunProvider.notifier,
                                                    )
                                                    .start(config);
                                              }
                                            },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('重新测试'),
                                    ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: state.running
                                          ? p.inset
                                          : p.accent,
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: p.subtle,
                                      minimumSize: const Size(0, 48),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed:
                                        state.running ||
                                            state.results.isEmpty ||
                                            _exporting
                                        ? null
                                        : _showExportSheet,
                                    icon: Icon(
                                      state.running
                                          ? Icons.lock_outline
                                          : Icons.ios_share,
                                    ),
                                    label: Text(
                                      state.running ? '等待完成' : '导出诊断报告',
                                    ),
                                  ),
                                ]
                                .map(
                                  (button) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: button,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

PreferredSizeWidget _bar(BuildContext context) => AppBar(
  leading: BackButton(
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    },
  ),
  backgroundColor: Theme.of(context).brightness == Brightness.light
      ? const Color(0xFFFBF9F8)
      : BusyBoxPalette.of(context).page,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  titleSpacing: 4,
  toolbarHeight: 56,
  title: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Ping 测试', style: PageHeaderTypography.title),
      Text('BusyBox', style: PageHeaderTypography.subtitle),
    ],
  ),
);
Widget _card(BuildContext context, Widget child) => Container(
  width: double.infinity,
  margin: const EdgeInsets.only(bottom: 10),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: BusyBoxPalette.of(context).canvas,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
    ],
  ),
  child: DefaultTextStyle.merge(
    style: const TextStyle(fontFamily: 'IBMPlexSans'),
    child: child,
  ),
);
void _notice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

String _percent(double? value) => value == null
    ? '—'
    : value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
Widget _historyMetric(
  BuildContext context,
  String label,
  String value,
  Color color,
) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  decoration: BoxDecoration(
    color: BusyBoxPalette.of(context).inset,
    borderRadius: BorderRadius.circular(8),
  ),
  height: 36,
  child: FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            color: BusyBoxPalette.of(context).muted,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  ),
);

// 设计稿的虚线按钮边框，路径跟随实际布局尺寸。
class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 7) {
        canvas.drawPath(
          metric.extractPath(start, (start + 4).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => color != oldDelegate.color;
}
