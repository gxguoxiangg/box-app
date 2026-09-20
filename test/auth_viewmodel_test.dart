/// 登录失败计数与锁定测试。
library;

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/core/network/api_client_provider.dart';
import 'package:demo1/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('连续错误超过 5 次后应锁定 15 分钟', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(
            client: MockClient((http.Request request) async {
              return http.Response('{"detail":"Unauthorized"}', 401);
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final AuthController controller =
        container.read(authControllerProvider.notifier);

    await controller.login(username: 'tester', password: 'wrong');
    expect(
      container.read(authControllerProvider).errorMessage,
      'ⓘ 账号或密码错误。请再试一次',
    );

    for (int attempt = 2; attempt <= 6; attempt++) {
      await controller.login(username: 'tester', password: 'wrong');
    }
    final AuthState state = container.read(authControllerProvider);
    expect(state.failedAttempts, 6);
    expect(state.isLocked, isTrue);
    expect(state.lockedUntil, isNotNull);
    expect(state.errorMessage, '登录失败次数过多，请 15 分钟后再试');
  });
}
