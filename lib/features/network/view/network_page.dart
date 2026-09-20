/// 网络信息模块主页面。
///
/// 页面自上而下：
/// 1. 连接状态卡片（Wi-Fi 名称 / 移动数据 / 无连接）；
/// 2. 设备网络信息卡片（IP、MAC、网关等）；
/// 3. 「网站连通」延迟测试网格（每行 3 个，点击进入详情）；
/// 4. 底部操作栏（测试网速 / 预留按钮）。
///
/// 本页为纯 View，数据全部来自 [networkViewModelProvider]（MVVM 的 View 层）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../../home/data/tool_registry.dart';
import '../viewmodel/network_viewmodel.dart';
import 'widgets/connection_status_card.dart';
import 'widgets/latency_grid.dart';
import 'widgets/network_info_card.dart';

/// 网络信息模块页。
class NetworkPage extends ConsumerWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<NetworkData> asyncState = ref.watch(
      networkViewModelProvider,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // -----------------------------------------------------------------
            // 顶部栏：返回 + 标题
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: '返回',
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '网络信息',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // -----------------------------------------------------------------
            // 主体：按状态渲染
            // -----------------------------------------------------------------
            Expanded(child: _buildBody(context, ref, asyncState)),
          ],
        ),
      ),
    );
  }

  /// 根据异步状态渲染主体。
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<NetworkData> asyncState,
  ) {
    // 加载中
    if (asyncState.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    // 加载失败
    if (asyncState.hasError) {
      final Object? error = asyncState.error;
      return ErrorRetryView(
        message: error is ApiException ? error.message : '加载失败，请稍后重试',
        onRetry: () => ref.read(networkViewModelProvider.notifier).refresh(),
      );
    }

    // 数据渲染
    final NetworkData data = asyncState.value!;
    return RefreshIndicator(
      // 支持下拉刷新。
      onRefresh: () => ref.read(networkViewModelProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          // 1. 连接状态卡片
          ConnectionStatusCard(status: data.status),
          const SizedBox(height: 20),

          // 2. 设备网络信息卡片
          NetworkInfoCard(info: data.info),
          const SizedBox(height: 20),

          // 3. 网站连通延迟网格
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              '网站连通',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          LatencyGrid(latencies: data.latencies),
          const SizedBox(height: 20),

          // 4. 底部操作栏
          _buildActionBar(context),
        ],
      ),
    );
  }

  /// 底部操作按钮栏。
  ///
  /// 当前两个按钮：测试网速（已实现）+ 预留按钮（功能待定）。
  /// 后期新增操作时，在此追加 [Expanded] 包裹的按钮即可。
  Widget _buildActionBar(BuildContext context) {
    return Row(
      children: <Widget>[
        // 测试网速：内嵌打开测试站点。
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.speedTest),
            icon: const Icon(Icons.speed_rounded, size: 20),
            label: const Text('测试网速'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 预留按钮：功能待定。
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('功能开发中，敬请期待')));
            },
            icon: const Icon(Icons.more_horiz_rounded, size: 20),
            label: const Text('更多工具'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
