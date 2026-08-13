/// 轻量级 HTTP 请求封装。
///
/// 基于 `package:http`，统一处理：
/// - 请求超时
/// - JSON 解析
/// - 异常归一化（统一抛出 [ApiException]）
///
/// 后期如需拦截器（token 注入、日志上报等），可在此统一扩展。
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

/// 统一的网络异常类型，方便上层（ViewModel / 页面）分类处理与提示。
class ApiException implements Exception {
  /// 异常描述信息。
  final String message;

  /// 请求失败时的 HTTP 状态码（网络异常时为 null）。
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message'
      '${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// API 响应通用封装（对应后端返回的 `{ "success": bool, "data": ... }` 结构）。
///
/// 泛型 [T] 为业务数据类型；若 data 不存在可传 [Null]。
class ApiResponse<T> {
  /// 请求是否成功。
  final bool success;

  /// 业务数据。
  final T? data;

  const ApiResponse({required this.success, this.data});
}

/// HTTP 客户端封装类。
class ApiClient {
  /// 可注入的 http 客户端，便于测试时替换为 Mock。
  final http.Client _client;

  /// 可传入自定义 Client（例如测试用 MockClient），默认使用真实网络。
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// 发起 GET 请求并返回服务端 JSON 的 `data` 字段原始内容。
  ///
  /// [path] 为接口路径，如 `/api/article/1`。
  Future<Map<String, dynamic>> getJsonData(String path) async {
    final Uri uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    http.Response response;
    try {
      // 发送请求并等待响应，超时抛错统一处理。
      response = await _client.get(uri).timeout(AppConstants.requestTimeout);
    } catch (e) {
      // 网络层异常（DNS 失败、连接超时、socket 错误等）。
      throw ApiException('网络异常，请检查网络连接后重试（$e）');
    }

    // 非 2xx 状态码直接视为失败。
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        '服务器响应异常',
        statusCode: response.statusCode,
      );
    }

    // 解析 JSON。
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const ApiException('返回数据格式异常');
    }

    // 业务层失败标记（success == false）。
    if (json['success'] == false) {
      throw const ApiException('业务处理失败');
    }

    // 取出 data 字段；若缺失则返回空 Map，由上层自行容错。
    return (json['data'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
  }

  /// 关闭底层 http 客户端，释放连接资源。
  void dispose() => _client.close();
}
