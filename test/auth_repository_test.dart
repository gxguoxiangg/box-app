/// 认证仓库与会话模型测试。
library;

import 'dart:convert';

import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/features/auth/data/auth_repository.dart';
import 'package:demo1/features/auth/models/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('登录应使用表单 POST 并建立一小时内存会话', () async {
    final DateTime beforeRequest = DateTime.now();
    final MockClient client = MockClient((http.Request request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/login');
      expect(
        request.headers['content-type'],
        startsWith('application/x-www-form-urlencoded'),
      );
      expect(request.bodyFields, <String, String>{
        'username': 'tester',
        'password': 'secret',
      });
      return http.Response(
        jsonEncode(<String, dynamic>{
          'access_token': 'jwt-token',
          'token_type': 'bearer',
          'expires_in': 604800,
          'user': <String, dynamic>{'id': 1, 'username': 'tester'},
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });

    final AuthSession session = await AuthRepository(ApiClient(client: client))
        .login(username: 'tester', password: 'secret');

    expect(session.accessToken, 'jwt-token');
    expect(session.username, 'tester');
    expect(session.isExpired, isFalse);
    expect(
      session.expiresAt,
      isNot(beforeRequest.add(const Duration(hours: 1))),
    );
    expect(
      session.expiresAt.isAfter(
        beforeRequest.add(const Duration(minutes: 59, seconds: 59)),
      ),
      isTrue,
    );
  });
}
