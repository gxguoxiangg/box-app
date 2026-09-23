/// Markdown 所见即所得编辑器组件测试。
library;

import 'package:demo1/features/article/view/widgets/markdown_wysiwyg_editor.dart';
import 'package:demo1/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  testWidgets('Markdown 导入后直接显示为可编辑富文本', (WidgetTester tester) async {
    final GlobalKey<MarkdownWysiwygEditorState> editorKey =
        GlobalKey<MarkdownWysiwygEditorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: MarkdownWysiwygEditor(
              key: editorKey,
              inputRole: 'test-editor',
              initialMarkdown: '**实时内容**\n\n- 第一项',
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SuperEditor), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(editorKey.currentState!.markdown, contains('**实时内容**'));
    expect(editorKey.currentState!.markdown, contains('* 第一项'));
  });

  testWidgets('代码块按钮转换当前段落并应用可见样式', (WidgetTester tester) async {
    final GlobalKey<MarkdownWysiwygEditorState> editorKey =
        GlobalKey<MarkdownWysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: MarkdownWysiwygEditor(
              key: editorKey,
              inputRole: 'code-editor',
              initialMarkdown: 'print(1);',
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey<String>('markdown-wysiwyg-editor')),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('代码块'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(editorKey.currentState!.markdown, '```\nprint(1);\n```');
    final ParagraphComponent codeBlock = tester
        .widgetList<ParagraphComponent>(find.byType(ParagraphComponent))
        .singleWhere(
          (ParagraphComponent component) =>
              component.viewModel.blockType == codeAttribution,
        );
    final TextStyle codeStyle = codeBlock.viewModel.textStyleBuilder(
      <Attribution>{},
    );
    expect(codeStyle.fontFamily, 'monospace');
    expect(codeStyle.backgroundColor, isNotNull);
  });

  testWidgets('没有光标时点击代码块会创建可编辑代码段', (WidgetTester tester) async {
    final GlobalKey<MarkdownWysiwygEditorState> editorKey =
        GlobalKey<MarkdownWysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: MarkdownWysiwygEditor(
              key: editorKey,
              inputRole: 'empty-code-editor',
              initialMarkdown: '',
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('代码块'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(editorKey.currentState!.markdown, contains('```\n\n```'));
  });

  testWidgets('上传返回的相对图片地址可实时显示且 Markdown 保持相对路径', (WidgetTester tester) async {
    final GlobalKey<MarkdownWysiwygEditorState> editorKey =
        GlobalKey<MarkdownWysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: MarkdownWysiwygEditor(
              key: editorKey,
              inputRole: 'image-editor',
              initialMarkdown: '正文',
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    editorKey.currentState!.insertImage(
      url: '/media/43.png',
      altText: 'photo.jpg',
    );
    await tester.pump();

    const String expectedDisplayUrl =
        '${AppConstants.kbApiBaseUrl}/media/43.png';
    expect(
      find.byKey(const ValueKey<String>('wysiwyg-image-$expectedDisplayUrl')),
      findsOneWidget,
    );
    expect(
      editorKey.currentState!.markdown,
      contains('![photo.jpg](/media/43.png)'),
    );
    await tester.pumpAndSettle();
    expect(find.text('图片加载失败'), findsOneWidget);
  });
}
