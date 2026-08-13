# 更新文档

> 对应 `update1.md` 的需求，记录本次迭代的详细更改与说明。

---

## 一、本次迭代概览

| 需求 | 状态 | 说明 |
| --- | --- | --- |
| 全局设置支持深色模式切换 | ✅ 已完成 | 明亮 / 黑暗主题实时切换，并持久化 |
| 新增「网络信息」功能模块 | ✅ 已完成 | 连接状态头部 + 设备网络信息 + 网站连通延迟网格 + 底部操作栏 |
| 注释丰富、便于后期扩展 | ✅ 已完成 | 全部新增代码含中文文档注释与扩展指引 |
| 生成更新文档 | ✅ 本文件 | — |

---

## 二、深色模式

### 2.1 实现方案

| 文件 | 作用 |
| --- | --- |
| `lib/core/theme/theme_controller.dart`（新增） | 主题状态控制器（Riverpod `AsyncNotifier<ThemeMode>`） |
| `lib/app/app.dart`（修改） | 根组件订阅主题模式，通过 `MaterialApp.themeMode` 切换明/暗 |
| `lib/features/settings/view/settings_page.dart`（修改） | 「深色模式」改为可用开关（`SwitchListTile`） |

### 2.2 关键设计

- **状态管理**：`ThemeController` 继承 `AsyncNotifier<ThemeMode>`。之所以用 `AsyncNotifier`，是因为首次启动需要**异步读取**本地持久化的主题值；读取完成前 UI 以明亮模式兜底（`.value ?? ThemeMode.light`），避免闪屏。
- **持久化**：使用 `shared_preferences` 保存 `theme_mode` 键（`dark` / `light`），重启应用后主题保持。
- **切换流程**：设置页开关 → `setDarkMode(dark:)` → ① 立即更新内存状态（触发全局 UI 重建）② 异步写入本地存储。
- **后续扩展**：
  - 如需「跟随系统」选项，可在 `ThemeController` 中增加 `ThemeMode.system` 分支；
  - 如需更多外观设置（字体、强调色），可扩展同一控制器或新增设置分组。

---

## 三、网络信息模块

### 3.1 模块结构（MVVM 分层）

```
lib/features/network/
├── models/
│   ├── connection_type.dart      # 连接类型枚举 + 映射（wifi/mobile/none…）
│   ├── network_status.dart       # 连接状态（类型 + Wi-Fi 名称 + 展示文案）
│   ├── network_info_data.dart    # 设备网络详情（IP、网关、SSID 等）
│   └── latency_result.dart       # 单次延迟测试结果
├── data/
│   └── network_repository.dart   # 数据仓库（抽象接口 + 真实实现）
├── viewmodel/
│   └── network_viewmodel.dart    # 聚合三项数据，AsyncNotifier 管理三态
└── view/
    ├── network_page.dart         # 主页面
    ├── latency_detail_page.dart  # 延迟详情页（简化版）
    ├── speed_test_page.dart      # 网速测试页（内嵌 WebView）
    └── widgets/
        ├── connection_status_card.dart  # 顶部连接状态卡片
        ├── network_info_card.dart       # 设备信息卡片
        └── latency_grid.dart            # 每行 3 个的延迟卡片网格
```

### 3.2 各功能点实现说明

#### ① 顶部连接状态（对应需求 2.1）

- 通过 `connectivity_plus` 获取连接类型：
  - Wi-Fi → 显示 Wi-Fi 名称（SSID，由 `network_info_plus` 提供）；
  - 移动数据 → 显示「移动数据」；
  - 无连接 → 显示「无连接」。
- 展示文案逻辑集中在 `NetworkStatus.displayLabel`，便于复用与测试。

#### ② 设备网络信息（对应需求 2.2）

- 通过 `network_info_plus` 获取 IP（IPv4 / IPv6）、子网掩码、网关、广播地址、SSID、BSSID。
- 以「两列网格」卡片展示；字段为 null 时显示「—」，避免空指针。
- **预留字段**：MAC 地址、信道、协商速率、频段已在 `NetworkInfoData` 中定义。
  > 说明：现代系统（尤其 Android 8+ / iOS）对真实 MAC、信道、频段等限制获取，
  > `network_info_plus` 亦不直接提供，故当前置为 null；后期可通过平台原生 API
  > （如 Android `WifiManager`）补充，只需在模型与信息卡片各加一项即可。

#### ③ 网站连通延迟网格（对应需求 2.3）

- 使用 `GridView` 实现**每行 3 个**的卡片布局；
- 默认测试站点：`www.baidu.com`、`www.qq.com`、`www.taobao.com`、
  `github.com`、`www.bing.com`、`www.google.com`（可在
  `NetworkRepository.defaultTestHosts` 集中修改 / 后期远程下发）；
- 延迟通过 `http` GET 请求实测（带 5s 超时），成功显示 `xx ms`，失败显示「不可达」；
- 点击卡片进入 `LatencyDetailPage`（**简化版**：展示主机、地址、状态、延迟、测试时间），
  后期可在此迭代升级（多次采样、延迟曲线等）。

#### ④ 底部操作栏（对应需求 2.4）

- 「测试网速」按钮 → 跳转 `SpeedTestPage`，内嵌 WebView 加载 `https://test.ustc.edu.cn/`；
- 「更多工具」按钮 → 占位（点击提示「功能开发中」），后期迭代接入；
- 操作栏使用 `Row + Expanded` 布局，新增按钮只需追加 `Expanded` 包裹的按钮即可。

### 3.3 平台注意事项

| 平台 | WebView（网速测试） | connectivity_plus | network_info_plus |
| --- | --- | --- | --- |
| Android / iOS | ✅ 内嵌 | ✅ | ✅（Wi-Fi 信息） |
| macOS / Windows | ✅ 内嵌（WebView2 等） | ✅ | ⚠️ 部分方法可用 |
| **Web** | ❌ 不支持内嵌，回退为「提示 + 在浏览器打开」 | ✅（类型判定有限） | ❌ 不支持（返回 null） |

- WebView 的 Web 回退逻辑在 `SpeedTestPage._buildWebFallback` 中，通过 `kIsWeb` 判断；
- 所有插件调用均做了异常捕获（`_safeString`），单点失败不影响整体页面。

### 3.4 注册链路

1. 路由常量：`AppRoutes.network`、`AppRoutes.speedTest`（`tool_registry.dart`）；
2. 路由注册：`app_router.dart` 中新增两个 `GoRoute`；
3. 工具入口：`toolRegistryProvider` 中登记「网络信息」工具（分类：网络类），
   主页点击即可进入。

---

## 四、依赖变更

| 依赖 | 版本 | 用途 |
| --- | --- | --- |
| `shared_preferences` | ^2.5.5 | 主题模式持久化 |
| `connectivity_plus` | ^7.3.1 | 网络连接类型判定 |
| `network_info_plus` | ^8.2.1 | Wi-Fi 名称、IP 等详情 |
| `webview_flutter` | ^4.14.1 | 网速测试内嵌网页 |
| `url_launcher` | ^6.3.2 | Web 平台回退：在浏览器打开测试页 |

---

## 五、测试

新增 / 更新测试（`flutter test` 全量通过，共 27 项）：

| 测试文件 | 覆盖内容 |
| --- | --- |
| `test/theme_test.dart`（新增） | 主题默认值、切换、持久化、重新加载 |
| `test/settings_page_test.dart`（新增） | 设置页深色模式开关交互 |
| `test/network_test.dart`（新增） | 连接类型映射、状态文案、延迟文案、ViewModel 聚合、网络页渲染 |
| 既有测试 | 未受影响，全部保持通过 |

**Mock 说明**：网络模块测试通过 `overrideWithValue` 注入 `FakeNetworkRepository`，
不依赖真实插件与网络，保证测试稳定、可离线运行。

---

## 六、后期扩展指引

1. **新增网络信息字段**：在 `NetworkInfoData` 加字段 → `NetworkInfoCard._buildItems` 加展示项；
2. **调整测试站点**：修改 `ConnectivityNetworkRepository.defaultTestHosts`；
3. **新增底部操作**：`NetworkPage._buildActionBar` 追加 `Expanded` 按钮 + 路由；
4. **升级延迟详情**：直接增强 `LatencyDetailPage`（无需改动主页面）；
5. **主题跟随系统**：在 `ThemeController` 增加 `ThemeMode.system` 分支，设置页加「跟随系统」选项。
