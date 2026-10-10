import 'package:demo1/core/theme/app_theme.dart';
import 'package:demo1/core/theme/busybox_palette.dart';
import 'package:demo1/features/article/models/article.dart';
import 'package:demo1/features/article/view/widgets/item_content.dart';
import 'package:demo1/features/article/view/widgets/wiki_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in <bool>[false, true]) {
    testWidgets('Wiki 320 宽${dark ? '深色' : '浅色'}正文不溢出，不编造作者日期', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: WikiTheme(
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ItemContent(
                  updatedAt: null,
                  item: ArticleItem(
                    id: 1,
                    articleId: 1,
                    position: 0,
                    question: '一个用于检查窄屏排版的较长知识库条目标题',
                    description: '```dart\nprint("hello");\n```',
                    causes: null,
                    solutions: null,
                    review: null,
                    keywords: '- 网络',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('问题描述'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('DART'), findsOneWidget);
      expect(find.textContaining('作者'), findsNothing);
      expect(find.textContaining('最后更新'), findsNothing);
      final cardContext = tester.element(find.byType(Card).first);
      expect(
        Theme.of(cardContext).cardTheme.color,
        dark ? BusyBoxPalette.dark.canvas : BusyBoxPalette.light.canvas,
      );
    });
  }
}
