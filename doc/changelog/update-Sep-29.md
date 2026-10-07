# 2026-09-29 主页、侧边栏与常用工具自定义更新

## 本次实现

- 根据 `doc/ui/home_page.html` 改造主页：品牌字样在第一帧出现，停留一秒再播放收缩、渐隐动画；字体和四个圆点进一步调细。顶部左侧为菜单、右侧仅保留个人中心；正文依次展示当前网络信息、常用工具、全部工具。个人中心尚无专属页面，点击后给出待开放提示。
- 根据 `doc/ui/sidebar_page.html` 更新抽屉：设置、统计、关于APP 三项。抽屉四角裁剪为圆角，“更多”标题使用较细字重，其下分隔线为 0.5 像素。设置和关于继续跳转已有页面；统计暂未开发，点击后给出提示。原软件更新路由保留，可供后续调用，但不在新版侧边栏展示。
- 根据 `doc/ui/custom_tools_page.html` 增加「自定义常用工具」页面和 `/custom-tools` 路由。去掉标题下方标语，状态栏与标题栏同色；两组工具都使用固定三列网格，只有已加入常用区的图标使用品牌蓝。常用区默认 Wiki、测网速、神机；可移除、添加，共最多六项。修改通过 Riverpod 同步到主页，并通过 `shared_preferences` 保存。未实现功能的工具只显示入口，不执行跳转。
- 将主页、抽屉、自定义页的蓝灰白配色抽成 `BusyBoxPalette`，作为 `ThemeExtension` 挂在亮色和深色 `AppTheme` 上。后续主题功能可替换该扩展中的颜色值，无需逐页改常量。
- 主页网络摘要继续读取现有 `NetworkRepository`，显示连接状态与可用地址；缺失数据用「—」表示。长按任一有值的信息卡片，会将该值复制到剪贴板。
- **VPN 下 MAC 为空的原因**：既有 Repository 将“设备 MAC 地址”固定为 `null`；`network_info_plus.getWifiBSSID()` 读取的是 Wi-Fi 接入点的 MAC，不能冒充设备自身 MAC。现改为明确展示“Wi-Fi 接入点 MAC”，即使 VPN 是当前连接类型也从底层 Wi-Fi 读取 BSSID，格式统一为 `XXXX-XXXX-XXXX`，过滤无效及系统脱敏地址。Android 缺少精确位置授权时由用户点击按钮请求，授权后刷新网络摘要；如果设备未连接 Wi-Fi、系统定位关闭或平台禁止访问，仍显示「—」。

权限依据：[network_info_plus 的 Android 权限说明](https://pub.dev/packages/network_info_plus#android)、[Android WifiInfo API 文档](https://developer.android.com/reference/android/net/wifi/WifiInfo)。

## 主要文件

| 文件 | 变更 |
| --- | --- |
| `lib/core/theme/busybox_palette.dart`、`app_theme.dart` | 统一配色模板及明暗主题注册 |
| `lib/features/home/view/home_page.dart` | 新版主页布局与自定义入口 |
| `lib/shared/widgets/app_drawer.dart` | 新版侧边栏 |
| `lib/features/home/view/custom_tools_page.dart` | 自定义界面与增减交互 |
| `lib/features/home/data/home_tool_options.dart`、`viewmodel/home_pinned_viewmodel.dart` | 工具目录与常用工具持久化 |
| `lib/app/router/app_router.dart`、`features/home/data/tool_registry.dart` | 新页面路由 |
| `test/home_smoke_test.dart`、`test/home_drawer_test.dart`、`test/home_custom_tools_test.dart` | 主页、抽屉、自定义行为与配色测试 |
| `lib/features/network/models/network_info_data.dart`、`data/wifi_access_permission.dart` | 接入点 MAC 规范化与 Android 授权通道 |
| `android/app/src/main/AndroidManifest.xml`、`MainActivity.kt` | 按需请求接入点信息所需的位置权限 |

## 验证

- `flutter analyze`：0 个问题。
- `flutter test`：76 项通过；覆盖动画时序、手机三列布局、图标颜色、状态栏颜色、抽屉圆角、VPN 接入点 MAC 的格式化、长按复制和授权后刷新。网络相关测试使用 Mock，不依赖真实联网。
- `flutter build apk --debug`：构建成功，生成 `build/app/outputs/flutter-apk/app-debug.apk`，包含 Android 原生权限通道。

Android 真机的 BSSID 读取结果仍受 Wi-Fi 是否连接、位置权限、系统定位开关及设备厂商策略影响；自动化测试和 APK 构建无法替代这些组合的真机验证。

## 后期扩展

- 在设置页增加主题模板选择时，可定义新的 `BusyBoxPalette` 实例并通过 `ThemeData.extensions` 注入。
- 为六项展示工具填入实际 `routePath` 后即可打开功能页；「神机」维持暂未开发状态。
- 如需个人中心和统计页面，可添加相应路由替换目前的提示。

## 补充修正：侧边栏状态栏遮罩与主页常用图标

- 修正侧边栏打开后顶部状态栏整条呈白色的问题。原因是主页将系统状态栏设置为不透明的面板底色，遮住了抽屉外侧的暗色遮罩。现改为透明状态栏，同时在主页安全区域底层绘制面板底色，使关闭抽屉时顶部配色一致，打开时未被抽屉覆盖的状态栏区域随遮罩变暗。
- 主页常用工具的功能图标统一使用配色模板的 `accent` 蓝色，与自定义页中已加入常用区的图标保持一致，并随明暗模板切换。
- 扩展已有组件测试，检查暗色遮罩覆盖顶部系统安全区域、状态栏保持透明，以及主页 Wiki 常用图标使用主题强调色。
- 验证结果：`flutter analyze` 无问题；主页、侧边栏和自定义页相关的 8 项测试全部通过。
- 本次仅修改 Flutter 界面与文档，前述 APK 构建记录对应上一轮修复，尚不包含本节变更。
