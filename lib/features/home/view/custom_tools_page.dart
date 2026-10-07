/// 常用工具自定义页，参照 doc/ui/custom_tools_page.html。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/busybox_palette.dart';
import '../../../shared/widgets/busybox_card.dart';
import '../data/home_tool_options.dart';
import '../viewmodel/home_pinned_viewmodel.dart';

/// 增减主页常用工具，修改实时保存并在返回主页后生效。
class CustomToolsPage extends ConsumerWidget {
  /// 创建自定义页。
  const CustomToolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BusyBoxPalette palette = BusyBoxPalette.of(context);
    final Brightness brightness = Theme.of(context).brightness;
    final List<String> pinned =
        ref.watch(homePinnedProvider).value ?? defaultPinnedTools;
    final List<HomeToolOption> selected =
        homeToolOptions.where((item) => pinned.contains(item.id)).toList()
          ..sort(
            (a, b) => pinned.indexOf(a.id).compareTo(pinned.indexOf(b.id)),
          );
    final List<HomeToolOption> available = homeToolOptions
        .where((item) => !pinned.contains(item.id))
        .toList();
    final HomePinnedController controller = ref.read(
      homePinnedProvider.notifier,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: palette.canvas,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: brightness,
      ),
      child: Scaffold(
        backgroundColor: palette.page,
        appBar: AppBar(
          backgroundColor: palette.canvas,
          foregroundColor: palette.ink,
          elevation: 1,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          shadowColor: palette.ink.withValues(alpha: 0.08),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: palette.canvas,
            statusBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: brightness,
          ),
          leading: IconButton(
            tooltip: '返回',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          titleSpacing: 0,
          title: const Text(
            '自定义常用工具',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.canvas,
                  shape: const StadiumBorder(),
                ),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _sectionHeader(
                          '常用工具',
                          '已选 ${selected.length}/${HomePinnedController.maxPinned} 项',
                          '点击减号快速卸载',
                          palette,
                        ),
                        const SizedBox(height: 8),
                        _toolGrid(
                          selected,
                          palette,
                          selected: true,
                          onPressed: controller.remove,
                        ),
                        const SizedBox(height: 24),
                        _sectionHeader(
                          '全部工具',
                          '共 ${available.length} 项可选',
                          '点击加号挂载到常用',
                          palette,
                        ),
                        const SizedBox(height: 8),
                        _toolGrid(
                          available,
                          palette,
                          selected: false,
                          onPressed: controller.add,
                          enabled:
                              pinned.length < HomePinnedController.maxPinned,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    String count,
    String hint,
    BusyBoxPalette palette,
  ) => Wrap(
    spacing: 6,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: palette.border.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          count,
          style: TextStyle(fontSize: 12, color: palette.muted),
        ),
      ),
      Text(hint, style: TextStyle(fontSize: 11, color: palette.subtle)),
    ],
  );

  Widget _toolGrid(
    List<HomeToolOption> items,
    BusyBoxPalette palette, {
    required bool selected,
    required Future<void> Function(String) onPressed,
    bool enabled = true,
  }) {
    return BusyBoxCard(
      padding: const EdgeInsets.all(16),

      child: items.isEmpty
          ? Text(
              selected ? '暂无常用工具' : '暂无可选工具',
              style: TextStyle(color: palette.muted),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 104,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final HomeToolOption item = items[index];
                return _CustomToolTile(
                  item: item,
                  palette: palette,
                  selected: selected,
                  enabled: enabled,
                  onPressed: () => onPressed(item.id),
                );
              },
            ),
    );
  }
}

class _CustomToolTile extends StatelessWidget {
  final HomeToolOption item;
  final BusyBoxPalette palette;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  const _CustomToolTile({
    required this.item,
    required this.palette,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${selected ? '移除' : '添加'} ${item.name}',
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        BusyBoxCard(
          radius: 16,
          color: palette.inset,
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            child: SizedBox(
              height: 104,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.canvas,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: selected ? palette.accent : palette.ink,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Material(
            color: selected ? palette.error : palette.border,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  selected ? Icons.remove : Icons.add,
                  color: selected ? palette.canvas : palette.ink,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
