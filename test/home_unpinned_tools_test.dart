import 'package:demo1/features/home/view/widgets/home_all_tools.dart';
import 'package:demo1/features/home/viewmodel/home_pinned_viewmodel.dart';
import 'package:demo1/features/home/data/tool_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('移除 Wiki 后全部工具可打开 Wiki，重新固定后不重复展示', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(child: HomeAllTools()),
          ),
        ),
        GoRoute(
          path: AppRoutes.articleList,
          builder: (_, _) => const Scaffold(body: Text('Wiki 页面')),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await container.read(homePinnedProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wiki'), findsNothing);
    await container.read(homePinnedProvider.notifier).remove('wiki');
    await tester.pumpAndSettle();
    expect(find.text('Wiki'), findsOneWidget);
    await tester.tap(find.text('Wiki'));
    await tester.pumpAndSettle();
    expect(find.text('Wiki 页面'), findsOneWidget);
    router.pop();
    await container.read(homePinnedProvider.notifier).add('wiki');
    await tester.pumpAndSettle();
    expect(find.text('Wiki'), findsNothing);
    expect(container.read(unpinnedHomeToolsProvider).length, 6);
  });
}
