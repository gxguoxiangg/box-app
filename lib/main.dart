/// 应用入口。
///
/// 整体架构：MVVM + Riverpod（状态管理）+ go_router（路由）。
///
/// 目录结构：
/// - app/      应用根组件与路由配置
/// - core/     通用层：常量、主题、网络封装
/// - features/ 业务功能模块（按功能拆分为 model / data / viewmodel / view）
/// - shared/   跨模块共享组件
library;

// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runApp(
    // ProviderScope：Riverpod 的根容器，必须包裹整个应用。
    const ProviderScope(
      child: App(),
    ),
  );
}

