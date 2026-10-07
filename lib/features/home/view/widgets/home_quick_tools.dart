/// 主页常用工具入口。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/busybox_palette.dart';
import '../../../../shared/widgets/busybox_card.dart';
import '../../data/home_tool_options.dart';
import '../../viewmodel/home_pinned_viewmodel.dart';

/// 设计稿中的三个常用工具；自定义入口由页面决定是否显示及如何响应。
class HomeQuickTools extends ConsumerWidget {
  /// 是否显示“自定义”按钮。
  final bool showCustomize;

  /// 点击“自定义”时的回调；为 null 时显示为不可点击。
  final VoidCallback? onCustomize;

  /// 创建常用工具区块。
  const HomeQuickTools({
    super.key,
    this.showCustomize = true,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BusyBoxPalette palette = BusyBoxPalette.of(context);
    final List<String> pinned =
        ref.watch(homePinnedProvider).value ?? defaultPinnedTools;
    final List<HomeToolOption> options = pinned
        .map((id) => homeToolOptions.where((item) => item.id == id).firstOrNull)
        .whereType<HomeToolOption>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '常用工具',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (showCustomize)
              TextButton.icon(
                onPressed: onCustomize,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('自定义'),
                style: TextButton.styleFrom(
                  foregroundColor: palette.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: palette.canvas,
                  shape: StadiumBorder(side: BorderSide(color: palette.border)),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (options.isEmpty)
          Text('暂无常用工具', style: TextStyle(color: palette.muted))
        else
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (final HomeToolOption item in options)
                  SizedBox(
                    width: (constraints.maxWidth - 20) / 3,
                    child: _QuickToolTile(
                      id: item.id,
                      title: item.name,
                      subtitle: item.description,
                      icon: item.icon,
                      palette: palette,
                      onTap: item.routePath == null
                          ? null
                          : () => context.push(item.routePath!),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickToolTile extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final BusyBoxPalette palette;
  final VoidCallback? onTap;

  const _QuickToolTile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.palette,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BusyBoxCard(
      onTap: onTap,
      child: SizedBox(
        key: ValueKey<String>('quick-tool-$id'),

        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.inset,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: palette.accent),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.subtle, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
