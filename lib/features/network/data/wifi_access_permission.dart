/// Android Wi-Fi 接入点信息的按需授权入口。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 仅当用户主动读取接入点 MAC 时请求位置权限。
abstract final class WifiAccessPermission {
  static const MethodChannel _channel = MethodChannel('busybox/wifi_access');

  /// 当前平台是否可通过本应用的原生授权通道请求权限。
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 请求 Android 的精确位置权限；其他平台返回 false。
  static Future<bool> request() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestLocationPermission') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
