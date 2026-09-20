/// Wiki 新增条目页面。
///
/// 页面由 7 个可左右滑动的步骤组成：五个文字小节、关键词与最终总览。
/// 编辑状态和提交逻辑由 Riverpod ViewModel 管理，View 只处理输入与交互。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/markdown_view.dart';
import '../../auth/models/auth_session.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../home/data/tool_registry.dart';
import '../models/article_draft.dart';
import '../models/article_submission.dart';
import '../models/keyword_collection.dart';
import '../viewmodel/article_draft_viewmodel.dart';
import '../viewmodel/article_viewmodel.dart';

/// Wiki 条目新增页面。
class ArticleCreatePage extends ConsumerStatefulWidget {
  const ArticleCreatePage({super.key});

  @override
  ConsumerState<ArticleCreatePage> createState() => _ArticleCreatePageState();
}

class _ArticleCreatePageState extends ConsumerState<ArticleCreatePage> {
  static const List<String> _stepLabels = <String>[
    '问题标题',
    '具体描述',
    '产生原因',
    '解决方案',
    '复盘',
    '关键字',
    '总览',
  ];

  final PageController _pageController = PageController();
  final Map<DraftSection, TextEditingController> _controllers =
      <DraftSection, TextEditingController>{};
  final Map<DraftSection, FocusNode> _focusNodes =
      <DraftSection, FocusNode>{};
  final TextEditingController _overviewController = TextEditingController();
  final FocusNode _overviewFocus = FocusNode();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final ArticleDraft draft =
        ref.read(articleDraftControllerProvider).draft;
    for (final DraftSection section in DraftSection.values) {
      _controllers[section] =
          TextEditingController(text: draft.textFor(section));
      final FocusNode node = FocusNode()..addListener(_refreshFocusState);
      _focusNodes[section] = node;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final AuthSession? session =
          ref.read(authSessionProvider.notifier).validSession;
      if (session == null) context.go(AppRoutes.login);
    });
  }

  void _refreshFocusState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes.values) {
      node
        ..removeListener(_refreshFocusState)
        ..dispose();
    }
    _overviewController.dispose();
    _overviewFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ArticleDraftState state = ref.watch(articleDraftControllerProvider);
    ref.listen<ArticleDraftState>(articleDraftControllerProvider,
        (ArticleDraftState? previous, ArticleDraftState next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) _confirmDelete();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '关闭并删除草稿',
            onPressed: _confirmDelete,
            icon: const Icon(Icons.close_rounded),
          ),
          title: const Text('新增 Wiki 条目'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(5),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _stepLabels.length,
              minHeight: 3,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: <Widget>[
                    Text(
                      _stepLabels[_currentPage],
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Text('${_currentPage + 1} / ${_stepLabels.length}'),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _stepLabels.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (BuildContext context, int index) {
                    if (index < DraftSection.values.length) {
                      return _buildTextStep(DraftSection.values[index], state);
                    }
                    if (index == DraftSection.values.length) {
                      return _buildKeywordStep(state);
                    }
                    return _buildCommitStep(state);
                  },
                ),
              ),
              _buildPageNavigation(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextStep(DraftSection section, ArticleDraftState state) {
    final TextEditingController controller = _controllers[section]!;
    final FocusNode focusNode = _focusNodes[section]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                section.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Divider(height: 24),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: section == DraftSection.question
                        ? '请输入问题标题...'
                        : '请输入 Markdown 内容...',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (String value) => ref
                      .read(articleDraftControllerProvider.notifier)
                      .updateText(section, value),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: focusNode.hasFocus
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _MarkdownToolbar(
                          isUploading: state.isUploading,
                          cameraEnabled: section != DraftSection.question,
                          onInsert: (String value) =>
                              _insertText(section, value),
                          onCamera: () => _captureImage(section),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordStep(ArticleDraftState state) {
    final AsyncValue<KeywordCollection> keywords =
        ref.watch(articleKeywordsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '关键字（可多选）',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Divider(height: 24),
              Expanded(
                child: keywords.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => Center(
                    child: FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(articleKeywordsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('重新加载关键字'),
                    ),
                  ),
                  data: (KeywordCollection collection) =>
                      SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final String keyword in collection.keywords)
                          FilterChip(
                            label: Text(keyword),
                            selected: state.draft.keywords.contains(keyword),
                            onSelected: (_) => ref
                                .read(articleDraftControllerProvider.notifier)
                                .toggleKeyword(keyword),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommitStep(ArticleDraftState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '文章预览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Divider(height: 24),
                MarkdownView(markdown: state.draft.markdownOverview),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _overviewController,
          focusNode: _overviewFocus,
          minLines: 10,
          maxLines: 20,
          decoration: const InputDecoration(
            labelText: '编辑 Markdown 总览',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (String value) => ref
              .read(articleDraftControllerProvider.notifier)
              .updateOverview(value),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isSubmitting ? null : _confirmDelete,
                icon: const Icon(Icons.close_rounded),
                label: const Text('删除草稿'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: state.isSubmitting ? null : _confirmSubmit,
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('提交'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageNavigation(ArticleDraftState state) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: '上一张卡片',
              onPressed: _currentPage == 0 ? null : () => _movePage(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            const Spacer(),
            if (state.isUploading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('正在上传图片...'),
              ),
            IconButton.filled(
              tooltip: '下一张卡片',
              onPressed: _currentPage == _stepLabels.length - 1
                  ? null
                  : () => _movePage(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentPage = index);
    if (index < DraftSection.values.length) {
      final DraftSection section = DraftSection.values[index];
      final TextEditingController controller = _controllers[section]!;
      final String currentValue =
          ref.read(articleDraftControllerProvider).draft.textFor(section);
      if (controller.text != currentValue) {
        controller
          ..text = currentValue
          ..selection = TextSelection.collapsed(offset: currentValue.length);
      }
    }
    if (index == _stepLabels.length - 1) {
      final String markdown =
          ref.read(articleDraftControllerProvider).draft.markdownOverview;
      _overviewController
        ..text = markdown
        ..selection = TextSelection.collapsed(offset: markdown.length);
    }
  }

  void _movePage(int delta) {
    _pageController.animateToPage(
      _currentPage + delta,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _insertText(DraftSection section, String insertion) {
    final TextEditingController controller = _controllers[section]!;
    final TextSelection selection = controller.selection;
    final int start = selection.isValid ? selection.start : controller.text.length;
    final int end = selection.isValid ? selection.end : controller.text.length;
    final String next = controller.text.replaceRange(start, end, insertion);
    controller
      ..text = next
      ..selection = TextSelection.collapsed(offset: start + insertion.length);
    ref
        .read(articleDraftControllerProvider.notifier)
        .updateText(section, next);
  }

  Future<void> _captureImage(DraftSection section) async {
    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (photo == null || !mounted) return;
      final DraftImage? image = await ref
          .read(articleDraftControllerProvider.notifier)
          .uploadImage(
            bytes: await photo.readAsBytes(),
            filename: photo.name,
            section: section,
          );
      if (image != null && mounted) {
        _insertText(section, '\n![${image.altText}](${image.url})\n');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前设备无法打开相机')),
      );
    }
  }

  Future<void> _confirmSubmit() async {
    final bool confirmed = await _showConfirmation(
      title: '确认提交？',
      confirmLabel: '提交',
    );
    if (!confirmed || !mounted) return;
    final ArticleSubmission? result =
        await ref.read(articleDraftControllerProvider.notifier).submit();
    if (!mounted) return;
    if (result == null) {
      if (ref.read(authSessionProvider) == null) context.go(AppRoutes.login);
      return;
    }
    ref
      ..invalidate(articleProvider)
      ..invalidate(articleKeywordsProvider);
    ref.read(articleDraftControllerProvider.notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('提交成功（条目 ${result.itemId}）')),
    );
    context.go(AppRoutes.articleList);
  }

  Future<void> _confirmDelete() async {
    final bool confirmed = await _showConfirmation(
      title: '删除草稿？',
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;
    ref.read(articleDraftControllerProvider.notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('草稿已删除')),
    );
    context.go(AppRoutes.articleList);
  }

  Future<bool> _showConfirmation({
    required String title,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// 输入框聚焦时显示在键盘上方的 Markdown 快捷工具栏。
class _MarkdownToolbar extends StatelessWidget {
  final bool isUploading;
  final bool cameraEnabled;
  final ValueChanged<String> onInsert;
  final VoidCallback onCamera;

  const _MarkdownToolbar({
    required this.isUploading,
    required this.cameraEnabled,
    required this.onInsert,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(28),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _button('加粗', Icons.format_bold_rounded, () => onInsert('**粗体**')),
          _button('代码块', Icons.code_rounded,
              () => onInsert('```\n代码\n```')),
          _button('有序列表', Icons.format_list_numbered_rounded,
              () => onInsert('1. ')),
          _button('无序列表', Icons.format_list_bulleted_rounded,
              () => onInsert('- ')),
          _button(
            '拍照',
            isUploading ? Icons.hourglass_top_rounded : Icons.photo_camera_rounded,
            cameraEnabled && !isUploading ? onCamera : null,
          ),
        ],
      ),
    );
  }

  Widget _button(String tooltip, IconData icon, VoidCallback? onPressed) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}

/// 后期扩展：可增加本地草稿持久化、图片缩略图管理和离线重试队列。
