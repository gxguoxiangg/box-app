/// Wiki 新增条目页面。
///
/// 页面由 7 个可左右滑动的步骤组成：五个文字小节、关键词与最终总览。
/// 编辑状态和提交逻辑由 Riverpod ViewModel 管理，View 只处理输入与交互。
library;

import 'package:flutter/material.dart';
import 'widgets/wiki_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/models/auth_session.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../home/data/tool_registry.dart';
import '../models/article_draft.dart';
import '../models/article.dart';
import 'widgets/item_content.dart';
import '../models/article_submission.dart';
import '../models/keyword_collection.dart';
import '../viewmodel/article_draft_viewmodel.dart';
import '../viewmodel/article_viewmodel.dart';
import 'widgets/markdown_wysiwyg_editor.dart';

/// Wiki 条目新增页面。
class ArticleCreatePage extends StatelessWidget {
  /// 创建 Wiki 页面并应用知识库主题。
  const ArticleCreatePage({super.key});

  @override
  Widget build(BuildContext context) =>
      WikiTheme(child: _ArticleCreatePageBody());
}

class _ArticleCreatePageBody extends ConsumerStatefulWidget {
  const _ArticleCreatePageBody();

  @override
  ConsumerState<_ArticleCreatePageBody> createState() =>
      _ArticleCreatePageBodyState();
}

class _ArticleCreatePageBodyState
    extends ConsumerState<_ArticleCreatePageBody> {
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
  final Map<DraftSection, FocusNode> _focusNodes = <DraftSection, FocusNode>{};
  final Map<DraftSection, GlobalKey<MarkdownWysiwygEditorState>>
  _wysiwygEditorKeys = <DraftSection, GlobalKey<MarkdownWysiwygEditorState>>{
    for (final DraftSection section in DraftSection.values)
      if (section != DraftSection.question)
        section: GlobalKey<MarkdownWysiwygEditorState>(),
  };
  final GlobalKey<MarkdownWysiwygEditorState> _overviewEditorKey =
      GlobalKey<MarkdownWysiwygEditorState>();
  int _currentPage = 0;
  bool _editingOverview = false;

  @override
  void initState() {
    super.initState();
    final ArticleDraft draft = ref.read(articleDraftControllerProvider).draft;
    for (final DraftSection section in DraftSection.values) {
      _controllers[section] = TextEditingController(
        text: draft.textFor(section),
      );
      final FocusNode node = FocusNode()..addListener(_refreshFocusState);
      _focusNodes[section] = node;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final AuthSession? session = ref
          .read(authSessionProvider.notifier)
          .validSession;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ArticleDraftState state = ref.watch(articleDraftControllerProvider);
    ref.listen<ArticleDraftState>(articleDraftControllerProvider, (
      ArticleDraftState? previous,
      ArticleDraftState next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
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
          title: const Text('新增文章'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: WikiTag('卡片 ${_currentPage + 1} / 7'),
            ),
          ],
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
                    Expanded(
                      child: Text(
                        '知识库条目构建器',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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

  Widget _stepCard({
    required int step,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '${step.toString().padLeft(2, '0')} / 07',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(icon, size: 22, color: colors.onSurfaceVariant),
                ],
              ),
            ),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStep(DraftSection section, ArticleDraftState state) {
    const icons = <IconData>[
      Icons.subject,
      Icons.description_outlined,
      Icons.psychology_outlined,
      Icons.terminal,
      Icons.verified_user_outlined,
    ];
    return _stepCard(
      step: section.index + 1,
      title: section.label,
      icon: icons[section.index],
      child: section == DraftSection.question
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '简要准确定义此条目的核心问题',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildSourceField(
                    section: section,
                    controller: _controllers[section]!,
                    focusNode: _focusNodes[section]!,
                  ),
                ),
              ],
            )
          : _buildMarkdownEditor(
              section: section,
              markdown: state.draft.textFor(section),
              state: state,
            ),
    );
  }

  Widget _buildSourceField({
    required DraftSection section,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      expands: true,
      minLines: null,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      decoration: const InputDecoration(
        hintText: '请输入问题标题...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      onChanged: (String value) => ref
          .read(articleDraftControllerProvider.notifier)
          .updateText(section, value),
    );
  }

  Widget _buildMarkdownEditor({
    required DraftSection section,
    required String markdown,
    required ArticleDraftState state,
  }) {
    return MarkdownWysiwygEditor(
      key: _wysiwygEditorKeys[section],
      inputRole: 'article-${section.name}',
      initialMarkdown: markdown,
      isUploading: state.isUploading,
      onCamera: () => _captureImage(section),
      onChanged: (String value) => ref
          .read(articleDraftControllerProvider.notifier)
          .updateText(section, value),
    );
  }

  Widget _buildKeywordStep(ArticleDraftState state) {
    final keywords = ref.watch(articleKeywordsProvider);
    void toggle(String keyword) => ref
        .read(articleDraftControllerProvider.notifier)
        .toggleKeyword(keyword);
    return _stepCard(
      step: 6,
      title: '关键字与标签',
      icon: Icons.sell_outlined,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('已选标签 (${state.draft.keywords.length})'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final keyword in state.draft.keywords)
                  InputChip(
                    label: Text('#$keyword'),
                    onDeleted: () => toggle(keyword),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('可选标签（轻触加入）'),
            const SizedBox(height: 10),
            keywords.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => TextButton.icon(
                onPressed: () => ref.invalidate(articleKeywordsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('重新加载关键字'),
              ),
              data: (KeywordCollection collection) {
                final available = collection.keywords
                    .where((tag) => !state.draft.keywords.contains(tag))
                    .toList();
                if (available.isEmpty) return const Text('暂无可选标签');
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final keyword in available)
                      ActionChip(
                        label: Text('#$keyword'),
                        avatar: const Icon(Icons.add, size: 16),
                        onPressed: () => toggle(keyword),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitStep(ArticleDraftState state) {
    final draft = state.draft;
    return _stepCard(
      step: 7,
      title: '信息总览与核对',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(_editingOverview ? '文章总览（可直接编辑）' : '文章实际渲染效果预览'),
              TextButton.icon(
                onPressed: () {
                  _flushCurrentEditor();
                  setState(() => _editingOverview = !_editingOverview);
                },
                icon: Icon(
                  _editingOverview
                      ? Icons.visibility_outlined
                      : Icons.edit_outlined,
                ),
                label: Text(_editingOverview ? '预览' : '编辑总览'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _editingOverview
                ? MarkdownWysiwygEditor(
                    key: _overviewEditorKey,
                    inputRole: 'article-overview',
                    initialMarkdown: draft.markdownOverview,
                    onChanged: (value) => ref
                        .read(articleDraftControllerProvider.notifier)
                        .updateOverview(value),
                  )
                : SingleChildScrollView(
                    child: ItemContent(
                      item: ArticleItem(
                        id: 0,
                        articleId: 0,
                        position: 0,
                        question: draft.question,
                        description: draft.description,
                        causes: draft.causes,
                        solutions: draft.solutions,
                        review: draft.review,
                        keywords: draft.keywords
                            .map((tag) => '- $tag')
                            .join('\n'),
                      ),
                      updatedAt: null,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isSubmitting ? null : _confirmDelete,
                  icon: const Icon(Icons.close),
                  label: const Text('删除草稿'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.isSubmitting ? null : _confirmSubmit,
                  icon: state.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('提交'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNavigation(ArticleDraftState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Tooltip(
                message: '上一张卡片',
                child: OutlinedButton.icon(
                  onPressed: _currentPage == 0 ? null : () => _movePage(-1),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('上一步'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tooltip(
                  message: '下一张卡片',
                  child: FilledButton(
                    onPressed: _currentPage == 6 ? null : () => _movePage(1),
                    child: Text(
                      _currentPage == 6
                          ? '已到总览'
                          : '下一步：${_stepLabels[_currentPage + 1]}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.isUploading ? '正在上传图片...' : '左右滑动卡片快速翻页',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // 切换预览或离开步骤前提交最新文本，避免编辑器 120ms 防抖尚未触发。
  void _flushCurrentEditor() {
    final controller = ref.read(articleDraftControllerProvider.notifier);
    if (_currentPage == 6 && _editingOverview) {
      final value = _overviewEditorKey.currentState?.markdown;
      if (value != null) controller.updateOverview(value);
    } else if (_currentPage > 0 && _currentPage < DraftSection.values.length) {
      final section = DraftSection.values[_currentPage];
      final value = _wysiwygEditorKeys[section]?.currentState?.markdown;
      if (value != null) controller.updateText(section, value);
    }
  }

  void _onPageChanged(int index) {
    _flushCurrentEditor();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentPage = index);
    if (index < DraftSection.values.length) {
      final DraftSection section = DraftSection.values[index];
      final TextEditingController controller = _controllers[section]!;
      final String currentValue = ref
          .read(articleDraftControllerProvider)
          .draft
          .textFor(section);
      if (controller.text != currentValue) {
        controller
          ..text = currentValue
          ..selection = TextSelection.collapsed(offset: currentValue.length);
      }
    }
  }

  void _movePage(int delta) {
    _flushCurrentEditor();
    _pageController.animateToPage(
      _currentPage + delta,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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
        _wysiwygEditorKeys[section]?.currentState?.insertImage(
          url: image.url,
          altText: image.altText,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前设备无法打开相机')));
    }
  }

  Future<void> _confirmSubmit() async {
    _flushCurrentEditor();
    final bool confirmed = await _showConfirmation(
      title: '确认提交？',
      confirmLabel: '提交',
    );
    if (!confirmed || !mounted) return;
    final ArticleSubmission? result = await ref
        .read(articleDraftControllerProvider.notifier)
        .submit();
    if (!mounted) return;
    if (result == null) {
      if (ref.read(authSessionProvider) == null) context.go(AppRoutes.login);
      return;
    }
    ref
      ..invalidate(articleProvider)
      ..invalidate(articleKeywordsProvider);
    ref.read(articleDraftControllerProvider.notifier).clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('提交成功（条目 ${result.itemId}）')));
    context.go(AppRoutes.articleList);
  }

  Future<void> _confirmDelete() async {
    final bool confirmed = await _showConfirmation(
      title: '删除草稿？',
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;
    ref.read(articleDraftControllerProvider.notifier).clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('草稿已删除')));
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

/// 后期扩展：可增加本地草稿持久化、图片缩略图管理和离线重试队列。
