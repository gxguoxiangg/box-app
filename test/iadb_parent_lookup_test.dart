import 'dart:convert';
import 'package:demo1/core/network/api_client.dart';
import 'package:demo1/features/iadb/data/iadb_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('部门为空时保留接口返回的父级部门，不发送无依据的父级查询', () async {
    final client = ApiClient(
      baseUrl: iadbBaseUrl,
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/search');
        return http.Response(
          jsonEncode({
            'assets': [
              for (final department in [
                null,
                <String, Object?>{},
                {'name': ''},
                {'name': '  '},
              ])
                {
                  'asset': {'id': 1},
                  'department': department,
                  'department_parent': {'id': 9, 'name': '父级部门'},
                },
            ],
            'matched_records': [],
            'matched_asset_count': 4,
            'matched_record_count': 0,
            'limit': 20,
            'offset': 0,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(client.dispose);
    final result = await IadbRepository(client).search('test-token', 'test', 0);
    expect(
      result.assets.map((asset) => asset.department),
      everyElement('父级部门'),
    );
  });
  for (final missing in [false, true]) {
    test('真实 parent_id 结构补全层级并去重请求，父级缺失=$missing', () async {
      final calls = <String, int>{};
      final client = ApiClient(
        baseUrl: iadbBaseUrl,
        client: MockClient((request) async {
          final path = request.url.path;
          calls.update(path, (v) => v + 1, ifAbsent: () => 1);
          expect(request.headers['authorization'], 'Bearer test-token');
          if (path.endsWith('/search')) {
            return http.Response(
              jsonEncode({
                'assets': List.generate(
                  2,
                  (i) => {
                    'asset': {'id': i},
                    'department': {'id': 2, 'parent_id': 1, 'name': '当前部门'},
                    'location': {'id': 30, 'parent_id': 20, 'name': '当前位置'},
                  },
                ),
                'matched_records': [],
                'matched_asset_count': 2,
                'matched_record_count': 0,
                'limit': 20,
                'offset': 0,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (missing) return http.Response('{}', 404);
          final row = switch (path) {
            '/api/v1/tables/department/1' => {'id': 1, 'name': '父级部门'},
            '/api/v1/tables/location/20' => {
              'id': 20,
              'parent_id': 10,
              'name': '楼栋',
            },
            '/api/v1/tables/location/10' => {'id': 10, 'name': '园区'},
            _ => throw StateError('非预期请求'),
          };
          return http.Response(
            jsonEncode(row),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(client.dispose);
      final result = await IadbRepository(
        client,
      ).search('test-token', 'test', 0);
      expect(result.assets.first.department, missing ? '当前部门' : '父级部门 · 当前部门');
      expect(result.assets.first.location, missing ? '当前位置' : '园区 · 楼栋 · 当前位置');
      expect(calls.values.every((count) => count == 1), isTrue);
    });
  }
}
