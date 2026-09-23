/// Markdown 图片全屏查看页。
library;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// 全屏展示网络图片，支持自由拖动、双指缩放、分享和保存到本地。
class FullscreenImageViewer extends StatefulWidget {
  /// 要显示、分享和保存的完整图片地址。
  final String imageUrl;

  /// 图片替代文字，用于无障碍说明。
  final String semanticLabel;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.semanticLabel = 'Wiki 图片',
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      key: const ValueKey<String>('fullscreen-image-system-ui'),
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: _FullscreenImageScaffold(
        imageUrl: widget.imageUrl,
        semanticLabel: widget.semanticLabel,
        transformationController: _transformationController,
        onLongPress: _showImageActions,
      ),
    );
  }

  /// 长按图片后才显示操作栏，避免常驻按钮遮挡图片。
  Future<void> _showImageActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _ImageActionSheet(
        onShare: () {
          Navigator.of(sheetContext).pop();
          _shareImage();
        },
        onSave: () {
          Navigator.of(sheetContext).pop();
          _saveImage();
        },
      ),
    );
  }

  Future<void> _shareImage() async {
    try {
      await SharePlus.instance.share(
        ShareParams(uri: Uri.parse(widget.imageUrl), title: '分享图片'),
      );
    } catch (_) {
      _showMessage('暂时无法分享图片');
    }
  }

  Future<void> _saveImage() async {
    final ({String name, String extension, String mimeType}) file =
        _imageFileInfo(widget.imageUrl);
    try {
      await FileSaver.instance.saveFile(
        name: file.name,
        link: LinkDetails(link: widget.imageUrl),
        fileExtension: file.extension,
        mimeType: MimeType.custom,
        customMimeType: file.mimeType,
      );
      _showMessage('图片已保存到本地');
    } catch (_) {
      _showMessage('图片保存失败，请稍后再试');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  ({String name, String extension, String mimeType}) _imageFileInfo(
    String url,
  ) {
    final Uri uri = Uri.parse(url);
    final String sourceName = uri.pathSegments.isEmpty
        ? 'busybox-image'
        : uri.pathSegments.last;
    final int dotIndex = sourceName.lastIndexOf('.');
    final String rawExtension = dotIndex >= 0
        ? sourceName.substring(dotIndex + 1).toLowerCase()
        : 'jpg';
    final String extension = switch (rawExtension) {
      'jpeg' || 'jpg' || 'png' || 'gif' || 'webp' || 'bmp' => rawExtension,
      _ => 'jpg',
    };
    final String rawName = dotIndex > 0
        ? sourceName.substring(0, dotIndex)
        : sourceName;
    final String safeName = rawName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final String mimeType = switch (extension) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      _ => 'image/jpeg',
    };
    return (
      name: safeName.isEmpty ? 'busybox-image' : safeName,
      extension: extension,
      mimeType: mimeType,
    );
  }
}

/// 将图片页面主体拆为独立组件，使系统栏样式可以覆盖完整路由区域。
class _FullscreenImageScaffold extends StatelessWidget {
  final String imageUrl;
  final String semanticLabel;
  final TransformationController transformationController;
  final VoidCallback onLongPress;

  const _FullscreenImageScaffold({
    required this.imageUrl,
    required this.semanticLabel,
    required this.transformationController,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // 让 InteractiveViewer 的画布与整个可视区域等大。放大后图片可以
                  // 在完整屏幕范围内平移，不再受原先 80 像素边界限制。
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: onLongPress,
                    child: InteractiveViewer(
                      key: const ValueKey<String>('fullscreen-image-viewer'),
                      transformationController: transformationController,
                      minScale: 1,
                      maxScale: 6,
                      panEnabled: true,
                      panAxis: PanAxis.free,
                      boundaryMargin: EdgeInsets.zero,
                      clipBehavior: Clip.none,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: Image.network(
                          imageUrl,
                          semanticLabel: semanticLabel,
                          fit: BoxFit.contain,
                          loadingBuilder:
                              (_, Widget child, ImageChunkEvent? progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              '图片加载失败',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: IconButton.filledTonal(
                tooltip: '关闭图片',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageActionSheet extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _ImageActionSheet({required this.onShare, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey<String>('image-action-sheet'),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _ImageActionButton(
                  label: '分享',
                  icon: Icons.share_rounded,
                  onPressed: onShare,
                ),
                const SizedBox(width: 44),
                _ImageActionButton(
                  label: '保存本地',
                  icon: Icons.download_rounded,
                  onPressed: onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ImageActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton.filled(
          tooltip: label,
          iconSize: 26,
          padding: const EdgeInsets.all(16),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
