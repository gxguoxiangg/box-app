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
  String toString() =>
      'ApiException: $message'
      '${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// HTTP 客户端封装类。
class ApiClient {
  /// 可注入的 http 客户端，便于测试时替换为 Mock。
  final http.Client _client;

  /// 服务端基础地址（默认指向知识库后端）。
  final String baseUrl;

  /// 可传入自定义 Client（例如测试用 MockClient）与 baseUrl。
  ///
  /// 默认使用真实网络、默认后端地址。
  ApiClient({http.Client? client, this.baseUrl = AppConstants.kbApiBaseUrl})
    : _client = client ?? http.Client();

  /// 发起 GET 请求并返回服务端响应的完整 JSON 对象（Map）。
  ///
  /// 知识库后端直接返回业务数据（无 `{ success, data }` 包装），
  /// 因此这里不做 data 解包，由上层按各接口结构自行解析。
  ///
  /// [path] 为接口路径，如 `/api/v1/articles/1`。
  Future<Map<String, dynamic>> getJson(String path) async {
    final Uri uri = Uri.parse('$baseUrl$path');
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
      throw ApiException('服务器响应异常', statusCode: response.statusCode);
    }

    // 解析 JSON（按 UTF-8 解码，避免中文乱码）。
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const ApiException('返回数据格式异常');
    }
  }

  /// 发起表单 POST 请求并解析 JSON 响应。
  ///
  /// 登录接口要求 `application/x-www-form-urlencoded`，统一在网络层处理
  /// 请求头和错误状态码，Repository 不直接接触底层 HTTP 客户端。
  Future<Map<String, dynamic>> postFormJson(
    String path,
    Map<String, String> fields,
  ) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              'content-type': 'application/x-www-form-urlencoded',
            },
            body: fields,
          )
          .timeout(AppConstants.requestTimeout);
    } catch (e) {
      throw ApiException('网络异常，请检查网络连接后重试（$e）');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode == 401 ? '用户名或密码错误' : '服务器响应异常',
        statusCode: response.statusCode,
      );
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const ApiException('返回数据格式异常');
    }
  }

  /// 发起携带 Bearer Token 的 JSON POST 请求。
  ///
  /// 投稿接口使用该方法发送结构化条目数据。所有非 2xx 响应仍统一转换为
  /// [ApiException]，上层只需要根据状态码决定是否要求重新登录。
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    required String bearerToken,
    String invalidResponseMessage = '返回数据格式异常',
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              'authorization': 'Bearer $bearerToken',
              'content-type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(AppConstants.requestTimeout);
    } catch (e) {
      throw ApiException('网络异常，请检查网络连接后重试（$e）');
    }
    return _decodeJsonResponse(
      response,
      invalidResponseMessage: invalidResponseMessage,
    );
  }

  /// 上传一张图片并返回服务端 JSON。
  ///
  /// 使用字节而不是文件路径，确保 Android、iOS 和 Web 可复用同一网络层。
  Future<Map<String, dynamic>> postMultipartImage(
    String path, {
    required String bearerToken,
    required List<int> bytes,
    required String filename,
    String invalidResponseMessage = '返回数据格式异常',
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    http.Response response;
    try {
      final http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..headers['authorization'] = 'Bearer $bearerToken'
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );
      final http.StreamedResponse streamed = await _client
          .send(request)
          .timeout(AppConstants.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } catch (e) {
      throw ApiException('图片上传失败，请检查网络连接后重试（$e）');
    }
    return _decodeJsonResponse(
      response,
      invalidResponseMessage: invalidResponseMessage,
    );
  }

  Map<String, dynamic> _decodeJsonResponse(
    http.Response response, {
    required String invalidResponseMessage,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode == 401 ? '登录状态已失效' : '服务器响应异常',
        statusCode: response.statusCode,
      );
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(invalidResponseMessage);
    }
  }

  /// 关闭底层 http 客户端，释放连接资源。
  void dispose() => _client.close();
}
