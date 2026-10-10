/// Markdown 阅读交互测试。
library;

import 'package:demo1/shared/widgets/fullscreen_image_viewer.dart';
import 'package:demo1/shared/widgets/markdown_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('正文可选择且长按代码块复制代码', (WidgetTester tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownView(
            markdown: '正文内容\n\n```dart\nfinal value = 1;\n```',
          ),
        ),
      ),
    );

    expect(
      tester.widget<MarkdownBody>(find.byType(MarkdownBody)).selectable,
      isTrue,
    );
    await tester.longPress(
      find.byKey(const ValueKey<String>('markdown-code-block')),
    );
    await tester.pumpAndSettle();
    expect(find.text('代码已复制'), findsOneWidget);
    expect(copiedText, 'final value = 1;');
    expect(find.text('DART'), findsOneWidget);
    copiedText = null;
    await tester.tap(find.text('复制'));
    await tester.pump();
    expect(copiedText, 'final value = 1;');
  });

  testWidgets('点击 Markdown 图片进入可缩放全屏页', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownView(markdown: '![示例图](https://example.com/demo.png)'),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('markdown-image-https://example.com/demo.png'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FullscreenImageViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('查看图片'), findsNothing);
    expect(find.byTooltip('分享图片'), findsNothing);

    final AnnotatedRegion<SystemUiOverlayStyle> systemUiRegion = tester.widget(
      find.byKey(const ValueKey<String>('fullscreen-image-system-ui')),
    );
    expect(systemUiRegion.value.statusBarColor, Colors.black);
    expect(systemUiRegion.value.statusBarIconBrightness, Brightness.light);
    expect(systemUiRegion.value.systemNavigationBarColor, Colors.black);

    final InteractiveViewer viewer = tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey<String>('fullscreen-image-viewer')),
    );
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, 6);
    expect(viewer.boundaryMargin, EdgeInsets.zero);

    await tester.longPress(
      find.byKey(const ValueKey<String>('fullscreen-image-viewer')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('image-action-sheet')),
      findsOneWidget,
    );
    expect(find.text('分享'), findsOneWidget);
    expect(find.text('保存本地'), findsOneWidget);
  });
}
