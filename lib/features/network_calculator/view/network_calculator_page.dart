/// 网络计算器。后期扩展：其他模式通过独立页面接入，不能复用子网结果。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/busybox_palette.dart';
import '../../../core/theme/page_header_typography.dart';
import '../viewmodel/subnet_viewmodel.dart';

/// 参考 subnetmaskcalculator_page.html 的实时子网计算页面。
class NetworkCalculatorPage extends ConsumerWidget {
  /// 创建计算器。
  const NetworkCalculatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = BusyBoxPalette.of(context);
    final state = ref.watch(subnetProvider);
    final vm = ref.read(subnetProvider.notifier);
    final result = state.result;
    final background = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFFBF9F8)
        : p.page;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        centerTitle: false,
        titleSpacing: 4,
        toolbarHeight:
            (MediaQuery.textScalerOf(context).scale(18) * 1.3 +
                    MediaQuery.textScalerOf(context).scale(12) * 1.3 +
                    8)
                .clamp(56, double.infinity),
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: background)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: background),
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: '返回',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '网络计算器',
              style: PageHeaderTypography.title.copyWith(color: p.ink),
            ),
            Text(
              'BusyBox 工具魔盒',
              style: PageHeaderTypography.subtitle.copyWith(color: p.muted),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _mode(context, '子网掩码计算', Icons.lan_outlined, true),
                    const SizedBox(width: 8),
                    _mode(context, 'POE计算', Icons.bolt, false),
                    const SizedBox(width: 8),
                    _mode(context, '带宽计算', Icons.speed, false),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(context, [
                _heading(context, 'IP 地址与掩码', Icons.tune, '实时换算'),
                const SizedBox(height: 16),
                _labelPair(context, 'IPv4 节点地址', '十进制格式'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: p.inset,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('.'),
                          ),
                        Expanded(
                          child: Semantics(
                            label: 'IPv4 第 ${i + 1} 段',
                            child: TextFormField(
                              key: ValueKey('subnet-octet-$i'),
                              initialValue: state.octets[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: p.ink,
                                fontWeight: FontWeight.w500,
                              ),
                              textInputAction: i == 3
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: p.canvas,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) => vm.setOctet(i, value),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (state.error case final String error)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error, style: TextStyle(color: p.error)),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.inset,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final description = Row(
                        children: [
                          Icon(Icons.lock_clock_outlined, color: p.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '前缀长度\n由下方滑块平滑调节',
                              style: TextStyle(fontSize: 12, color: p.muted),
                            ),
                          ),
                        ],
                      );
                      final badge = Container(
                        key: const ValueKey('subnet-cidr-badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: p.canvas,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'CIDR ',
                                style: TextStyle(fontSize: 12, color: p.muted),
                              ),
                              TextSpan(
                                text: '/${state.prefix}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: p.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (constraints.maxWidth < 280 &&
                          MediaQuery.textScalerOf(context).scale(12) > 15) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            description,
                            const SizedBox(height: 8),
                            badge,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: description),
                          const SizedBox(width: 8),
                          badge,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _labelPair(
                  context,
                  '子网掩码',
                  '前缀: ${state.prefix} 位',
                  accent: true,
                ),
                Row(
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: p.inset,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      tooltip: '减少前缀长度',
                      onPressed: state.prefix > 1
                          ? () => vm.setPrefix(state.prefix - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 8,
                          activeTrackColor: p.border,
                          inactiveTrackColor: p.border,
                          activeTickMarkColor: Colors.transparent,
                          inactiveTickMarkColor: Colors.transparent,
                          thumbColor: p.accent,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          min: 1,
                          max: 32,
                          divisions: 31,
                          value: state.prefix.toDouble(),
                          label: '/${state.prefix}',
                          semanticFormatterCallback: (value) =>
                              '前缀 ${value.round()} 位',
                          onChanged: (value) => vm.setPrefix(value.round()),
                        ),
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: p.inset,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      tooltip: '增加前缀长度',
                      onPressed: state.prefix < 32
                          ? () => vm.setPrefix(state.prefix + 1)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              _card(context, [
                _heading(context, '计算结果', Icons.analytics_outlined, 'IPv4 标准'),
                const SizedBox(height: 16),
                if (result == null)
                  const Text('请输入有效地址后查看计算结果')
                else ...[
                  _field(context, '子网掩码 (Subnet Mask)', result.mask),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final network = _field(
                        context,
                        '网络号 (Network)',
                        result.network,
                      );
                      final broadcast = _field(
                        context,
                        '广播号 (Broadcast)',
                        result.broadcast ?? '—',
                        copy: result.broadcast != null,
                      );
                      if (constraints.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            network,
                            const SizedBox(height: 8),
                            broadcast,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: network),
                          const SizedBox(width: 8),
                          Expanded(child: broadcast),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _hostCount(context, result.usableHosts, result.totalHosts),
                  const SizedBox(height: 8),
                  _field(context, '可用地址范围 (Usable Range)', result.range),
                  if (result.prefix >= 31)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        result.prefix == 31
                            ? '/31 按点对点链路计算，两个地址均可用，无广播地址。'
                            : '/32 为单主机地址，无广播地址。',
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mode(
    BuildContext context,
    String title,
    IconData icon,
    bool selected,
  ) {
    final p = BusyBoxPalette.of(context);
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 36),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: selected ? p.accent : p.inset,
        foregroundColor: selected ? p.canvas : p.ink,
      ),
      onPressed: () {
        if (!selected) {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('暂未开放')));
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(title),
    );
  }

  Widget _card(BuildContext context, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: BusyBoxPalette.of(context).canvas,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _heading(
    BuildContext context,
    String title,
    IconData icon,
    String note,
  ) {
    final p = BusyBoxPalette.of(context);
    final heading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: p.inset,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: p.accent, size: 20),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ),
      ],
    );
    final trailing = note == '实时换算'
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_alt, size: 16, color: p.subtle),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  note,
                  style: TextStyle(fontSize: 12, color: p.subtle),
                ),
              ),
            ],
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: p.inset,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(note, style: TextStyle(fontSize: 12, color: p.muted)),
          );
    // 保持左右同行；两侧均有有限宽度，放大字体时在各自区域换行。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: heading),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Align(alignment: Alignment.centerRight, child: trailing),
        ),
      ],
    );
  }

  Widget _labelPair(
    BuildContext context,
    String label,
    String value, {
    bool accent = false,
  }) {
    final p = BusyBoxPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: accent ? 14 : 12, color: p.muted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent ? p.accent : p.subtle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _hostCount(BuildContext context, int usable, int total) {
    final p = BusyBoxPalette.of(context);
    // 两列共享行高，避免标签换行或数值字号不同造成垂直错位。
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.inset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FixedColumnWidth(8),
          2: FlexColumnWidth(2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        textBaseline: TextBaseline.alphabetic,
        children: [
          TableRow(
            children: [
              Text(
                '可用主机数量 (Hosts)',
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
              const SizedBox.shrink(),
              Text(
                '总分配空间',
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 12, color: p.subtle),
              ),
            ],
          ),
          TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.baseline,
                child: Text.rich(
                  key: const ValueKey('subnet-usable-count'),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$usable',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: p.accent,
                        ),
                      ),
                      TextSpan(
                        text: ' 台可用',
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox.shrink(),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.baseline,
                child: Text(
                  '$total 个 IP',
                  key: const ValueKey('subnet-total-count'),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    String value, {
    bool copy = true,
  }) {
    final p = BusyBoxPalette.of(context);
    final content = Container(
      key: ValueKey('subnet-result-$label'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
              ),
              if (copy) ...[
                const SizedBox(width: 4),
                Icon(Icons.copy_outlined, size: 16, color: p.accent),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
    // 整块结果可复制：紧凑图标仍有足够大的触摸目标。
    return Material(
      color: p.inset,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: copy
          ? Tooltip(
              message: '复制$label',
              child: Semantics(
                button: true,
                label: '复制$label',
                child: InkWell(
                  onTap: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(const SnackBar(content: Text('已复制')));
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(content: Text('复制失败，请重试')),
                          );
                      }
                    }
                  },
                  child: content,
                ),
              ),
            )
          : content,
    );
  }
}
