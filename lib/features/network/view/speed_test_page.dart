/// 网速测试页。
///
/// 内嵌 WebView 加载 `https://test.ustc.edu.cn/` 完成网速测试。
///
/// 平台说明：
/// - Android / iOS / macOS / Windows 由 `webview_flutter` 提供内嵌支持；
/// - **Web 端暂不支持 WebView**，此处回退为「提示 + 在浏览器打开」，
///   保证各平台均可用（后期可迭代为 iframe 或专用测试页）。
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 网速测试页。
class SpeedTestPage extends StatelessWidget {
  /// 测试地址（可后期改为常量/配置）。
  static const String testUrl = 'https://test.ustc.edu.cn/';

  const SpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('网速测试'),
      ),
      body: kIsWeb ? _buildWebFallback(context) : _buildWebView(context),
    );
  }

  /// 内嵌 WebView（移动端 / 桌面端）。
  Widget _buildWebView(BuildContext context) {
    // 初始化并加载测试地址。
    final WebViewController controller = WebViewController()
      // 允许执行页面内 JavaScript（部分测速脚本需要）。
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 背景色设为浅灰，避免加载白屏突兀。
      ..setBackgroundColor(Theme.of(context).colorScheme.surface)
      ..loadRequest(Uri.parse(testUrl));

    return WebViewWidget(controller: controller);
  }

  /// Web 平台回退：提示不支持内嵌 + 提供「在浏览器打开」。
  Widget _buildWebFallback(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.travel_explore_rounded,
            size: 56,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          const Text(
            '当前平台暂不支持应用内网页测试',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          const Text(
            '可在浏览器中打开测试页面',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openInBrowser(context),
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            label: const Text('在浏览器打开'),
          ),
        ],
      ),
    );
  }

  /// 调用系统浏览器打开测试地址。
  Future<void> _openInBrowser(BuildContext context) async {
    final Uri uri = Uri.parse(testUrl);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      // 打开失败时的兜底提示。
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('打开浏览器失败，请手动访问测试页面')));
    }
  }
}
