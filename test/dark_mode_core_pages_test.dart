/// 核心卡片在深色主题下的回归检查。
library;

import 'package:demo1/core/theme/app_theme.dart';
import 'package:demo1/features/article/models/article.dart';
import 'package:demo1/features/article/view/widgets/item_content.dart';
import 'package:demo1/features/article/view/widgets/wiki_theme.dart';
import 'package:demo1/core/theme/busybox_palette.dart';
import 'package:demo1/features/home/view/widgets/tool_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('深色主题下 Wiki 正文和章节卡片使用主题颜色', (tester) async {
    const ArticleItem item = ArticleItem(
      id: 1,
      articleId: 1,
      position: 0,
      question: 'Q - 深色标题',
      description: '正文',
      causes: null,
      solutions: null,
      review: null,
      keywords: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const WikiTheme(
          child: Scaffold(
            body: SingleChildScrollView(
              child: ItemContent(item: item, updatedAt: null),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('深色标题')).style?.color,
      BusyBoxPalette.dark.ink,
    );
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Material &&
            widget.type == MaterialType.card &&
            widget.color == BusyBoxPalette.dark.canvas,
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('深色主题下首页工具卡片不再使用白色背景', (tester) async {
    final ColorScheme colors = AppTheme.dark.colorScheme;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: ToolGrid()),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Material && widget.color == colors.surfaceContainerLow,
      ),
      findsWidgets,
    );
  });
}
