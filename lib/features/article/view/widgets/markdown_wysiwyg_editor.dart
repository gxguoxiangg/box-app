/// Wiki 投稿使用的 Markdown 所见即所得编辑器。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../../../core/constants/app_constants.dart';

/// 将 Markdown 转换为可直接编辑的富文本文档，并在每次编辑后导出 Markdown。
///
/// 页面和 ViewModel 仍然只保存 Markdown 字符串，第三方编辑器的数据结构被限制在
/// 此组件内部，避免数据层依赖 UI 实现。
class MarkdownWysiwygEditor extends StatefulWidget {
  /// 同一页面存在多个编辑器时用于区分系统输入法连接。
  final String inputRole;
  final String initialMarkdown;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCamera;
  final bool isUploading;

  const MarkdownWysiwygEditor({
    super.key,
    required this.inputRole,
    required this.initialMarkdown,
    required this.onChanged,
    this.onCamera,
    this.isUploading = false,
  });

  @override
  State<MarkdownWysiwygEditor> createState() => MarkdownWysiwygEditorState();
}

/// 公开状态仅用于页面在图片上传完成后向当前光标位置插入图片。
class MarkdownWysiwygEditorState extends State<MarkdownWysiwygEditor> {
  final MarkdownInlineUpstreamSyntaxPlugin _markdownPlugin =
      MarkdownInlineUpstreamSyntaxPlugin();
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late FocusNode _focusNode;
  Timer? _changeTimer;
  String _lastEmittedMarkdown = '';

  /// 当前富文本文档对应的标准 Markdown。
  String get markdown =>
      serializeDocumentToMarkdown(_document, syntax: MarkdownSyntax.normal);

  @override
  void initState() {
    super.initState();
    _initializeEditor(widget.initialMarkdown);
  }

  @override
  void didUpdateWidget(covariant MarkdownWysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ViewModel 会把本编辑器刚导出的 Markdown 再传回来，此时不能重建文档，
    // 否则光标会跳回开头。只有真正来自外部的新值才重新载入。
    if (widget.initialMarkdown != oldWidget.initialMarkdown &&
        widget.initialMarkdown != _lastEmittedMarkdown &&
        widget.initialMarkdown != markdown) {
      _disposeEditor();
      _initializeEditor(widget.initialMarkdown);
    }
  }

  void _initializeEditor(String markdown) {
    _document = deserializeMarkdownToDocument(markdown)
      ..addListener(_onDocumentChanged);
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
      isHistoryEnabled: true,
    );
    _focusNode = FocusNode();
    _lastEmittedMarkdown = serializeDocumentToMarkdown(
      _document,
      syntax: MarkdownSyntax.normal,
    );
  }

  @override
  void dispose() {
    _disposeEditor();
    super.dispose();
  }

  void _disposeEditor() {
    _changeTimer?.cancel();
    _document.removeListener(_onDocumentChanged);
    _editor.dispose();
    _composer.dispose();
    _focusNode.dispose();
  }

  void _onDocumentChanged(_) {
    _changeTimer?.cancel();
    _changeTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      final String value = markdown;
      if (value == _lastEmittedMarkdown) return;
      _lastEmittedMarkdown = value;
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildToolbar(context),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          Expanded(
            child: SuperEditor(
              key: const ValueKey<String>('markdown-wysiwyg-editor'),
              editor: _editor,
              focusNode: _focusNode,
              inputRole: widget.inputRole,
              componentBuilders: <ComponentBuilder>[
                const _WikiImageComponentBuilder(),
                ...defaultComponentBuilders,
              ],
              // 插件实例必须在组件生命周期内保持稳定；每次 build 新建会让
              // Super Editor 在卸载时找不到原附着记录。
              plugins: <SuperEditorPlugin>{_markdownPlugin},
              stylesheet: defaultStylesheet.copyWith(
                documentPadding: const EdgeInsets.all(14),
                addRulesAfter: <StyleRule>[
                  StyleRule(
                    BlockSelector.all,
                    (_, _) => <String, dynamic>{
                      Styles.textStyle: TextStyle(
                        color: colors.onSurface,
                        height: 1.45,
                      ),
                    },
                  ),
                  StyleRule(
                    const BlockSelector('code'),
                    (_, _) => <String, dynamic>{
                      Styles.padding: const CascadingPadding.symmetric(
                        vertical: 8,
                      ),
                      Styles.textStyle: TextStyle(
                        color: colors.onSurface,
                        backgroundColor: colors.surfaceContainerHighest,
                        fontFamily: 'monospace',
                        fontSize: 15,
                        height: 1.55,
                      ),
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: <Widget>[
            _toolbarButton('加粗', Icons.format_bold_rounded, () {
              _toggleInlineAttribution(boldAttribution);
            }),
            _toolbarButton('斜体', Icons.format_italic_rounded, () {
              _toggleInlineAttribution(italicsAttribution);
            }),
            _toolbarButton('代码块', Icons.code_rounded, _toggleCodeBlock),
            _toolbarButton(
              '有序列表',
              Icons.format_list_numbered_rounded,
              () => _toggleList(ListItemType.ordered),
            ),
            _toolbarButton(
              '无序列表',
              Icons.format_list_bulleted_rounded,
              () => _toggleList(ListItemType.unordered),
            ),
            if (widget.onCamera != null)
              _toolbarButton(
                '拍照',
                widget.isUploading
                    ? Icons.hourglass_top_rounded
                    : Icons.photo_camera_rounded,
                widget.isUploading ? null : widget.onCamera,
              ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(
    String tooltip,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed == null
          ? null
          : () {
              onPressed();
              _focusNode.requestFocus();
            },
      icon: Icon(icon, size: 20),
    );
  }

  void _toggleInlineAttribution(Attribution attribution) {
    final DocumentSelection? selection = _composer.selection;
    if (selection == null) return;
    if (selection.isCollapsed) {
      _composer.preferences.toggleStyle(attribution);
      return;
    }
    _editor.execute(<EditRequest>[
      ToggleTextAttributionsRequest(
        documentRange: selection,
        attributions: <Attribution>{attribution},
      ),
    ]);
  }

  void _toggleCodeBlock() {
    final DocumentSelection? selection = _composer.selection;
    if (selection == null) {
      _insertEmptyCodeBlock();
      return;
    }

    final List<DocumentNode> selectedNodes = _document
        .getNodesInside(selection.base, selection.extent)
        .where(
          (DocumentNode node) => node is ParagraphNode || node is ListItemNode,
        )
        .toList(growable: false);
    if (selectedNodes.isEmpty) return;

    final bool removeCodeStyle = selectedNodes.every(
      (DocumentNode node) =>
          node is ParagraphNode &&
          node.getMetadataValue(NodeMetadata.blockType) == codeAttribution,
    );
    final List<EditRequest> requests = <EditRequest>[];
    for (final DocumentNode node in selectedNodes) {
      if (node is ListItemNode) {
        requests.add(
          ConvertListItemToParagraphRequest(
            nodeId: node.id,
            paragraphMetadata: <String, dynamic>{
              NodeMetadata.blockType: codeAttribution,
            },
          ),
        );
      } else if (node is ParagraphNode) {
        requests.add(
          ChangeParagraphBlockTypeRequest(
            nodeId: node.id,
            blockType: removeCodeStyle ? null : codeAttribution,
          ),
        );
      }
    }
    _editor.execute(requests);
  }

  /// 编辑器尚未获得光标时，在文档末尾创建一个代码块并把光标放进去。
  void _insertEmptyCodeBlock() {
    final String nodeId = Editor.createNodeId();
    final ParagraphNode node = ParagraphNode(
      id: nodeId,
      text: AttributedText(),
      metadata: <String, dynamic>{NodeMetadata.blockType: codeAttribution},
    );
    _editor.execute(<EditRequest>[
      InsertNodeAtEndOfDocumentRequest(node),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
  }

  void _toggleList(ListItemType type) {
    final DocumentSelection? selection = _composer.selection;
    if (selection == null || selection.base.nodeId != selection.extent.nodeId) {
      return;
    }
    final DocumentNode? node = _document.getNodeById(selection.extent.nodeId);
    if (node is ParagraphNode) {
      _editor.execute(<EditRequest>[
        ConvertParagraphToListItemRequest(nodeId: node.id, type: type),
      ]);
    } else if (node is ListItemNode && node.type == type) {
      _editor.execute(<EditRequest>[
        ConvertListItemToParagraphRequest(nodeId: node.id),
      ]);
    } else if (node is ListItemNode) {
      _editor.execute(<EditRequest>[
        ChangeListItemTypeRequest(nodeId: node.id, newType: type),
      ]);
    }
  }

  /// 在当前光标位置插入已上传图片；编辑器尚未选中时追加到文档末尾。
  void insertImage({required String url, required String altText}) {
    final ImageNode image = ImageNode(
      id: Editor.createNodeId(),
      imageUrl: url,
      altText: altText,
    );
    if (_composer.selection == null) {
      _editor.execute(<EditRequest>[InsertNodeAtEndOfDocumentRequest(image)]);
    } else {
      _editor.execute(<EditRequest>[InsertNodeAtCaretRequest(node: image)]);
    }
    _focusNode.requestFocus();
  }
}

/// 为富文本编辑器中的 Wiki 图片补全相对地址，同时保留原始 Markdown URL。
class _WikiImageComponentBuilder implements ComponentBuilder {
  const _WikiImageComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    return const ImageComponentBuilder().createViewModel(document, node);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! ImageComponentViewModel) return null;
    return ImageComponent(
      componentKey: componentContext.componentKey,
      imageUrl: componentViewModel.imageUrl,
      expectedSize: componentViewModel.expectedSize,
      selection:
          componentViewModel.selection?.nodeSelection
              as UpstreamDownstreamNodeSelection?,
      selectionColor: componentViewModel.selectionColor,
      opacity: componentViewModel.opacity,
      imageBuilder: (BuildContext context, String sourceUrl) {
        final String displayUrl = _resolveWikiImageUrl(sourceUrl);
        return Image.network(
          displayUrl,
          key: ValueKey<String>('wysiwyg-image-$displayUrl'),
          fit: BoxFit.contain,
          loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
            if (progress == null) return child;
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, _, _) => const SizedBox(
            height: 160,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.broken_image_outlined, size: 36),
                  SizedBox(height: 8),
                  Text('图片加载失败'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _resolveWikiImageUrl(String sourceUrl) {
  final Uri? uri = Uri.tryParse(sourceUrl);
  if (uri == null || uri.hasScheme) return sourceUrl;
  return Uri.parse(AppConstants.kbApiBaseUrl).resolveUri(uri).toString();
}
