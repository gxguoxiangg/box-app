# 更新文档（2026-09-15）

> 对应 `doc/requirements/target-Sep-15.md`，记录本次主页 UI 更新。

## 一、本次迭代概览

| 需求 | 状态 | 说明 |
| --- | --- | --- |
| 修复主页状态栏颜色 | ✅ 已完成 | 主页根据当前主题同步状态栏背景色和图标亮度 |
| 主页搜索入口 | ✅ 已完成 | 移除顶部搜索输入框，改为右上角搜索图标 |
| 独立搜索页 | ✅ 已完成 | 顶部为完整搜索框，输入字符后立即连续匹配功能名称 |
| 搜索无结果状态 | ✅ 已完成 | 无匹配结果显示半透明大号“空” |
| 首次进入标题动画 | ✅ 已完成 | Guoxiang 旋转消失，LazyBox 渐隐，随后显示“主页” |
| 文章功能名称 | ✅ 已完成 | “文章内容”改为“Wiki” |
| 工具模块名称样式 | ✅ 已完成 | 工具卡片名称使用加粗深色文字 |

## 二、主页顶部栏

### 2.1 状态栏颜色

`HomePage` 使用 `AnnotatedRegion<SystemUiOverlayStyle>` 根据 `Theme.of(context)`
动态设置状态栏颜色。明亮主题使用页面背景色和深色图标，黑暗主题使用黑暗页面背景色和浅色图标，避免状态栏与页面出现明显色差。

### 2.2 搜索入口

主页顶部移除原有 `_SearchField`，保留菜单按钮、动画标题和右上角搜索按钮。
搜索按钮通过 `AppRoutes.search` 进入独立搜索页，路由仍由 go_router 集中管理。

## 三、功能搜索页

新增 `lib/features/home/view/search_page.dart`。

- 搜索框自动获得焦点；
- 每次输入通过 `ToolSearchController` 更新 Riverpod 状态；
- 采用连续字符串匹配，大小写不敏感；
- 搜索结果来自 `toolRegistryProvider`，点击结果进入对应功能路由；
- 搜索无结果时显示“空”；
- 搜索逻辑位于 `home_viewmodel.dart`，页面只负责展示和交互。

这种实现适合当前功能模块数量较少的情况。后期如果工具注册表来自远程配置，
只需替换 Provider 数据来源即可。

## 四、首次进入标题动画

新增 `_AnimatedHomeTitle`，使用 `AnimationController` 和 `AnimatedBuilder` 管理动画：

1. `Guoxiang` 在第一阶段旋转并透明消失；
2. `LazyBox` 在第二阶段渐变消失；
3. “主页”从左侧轻微移动并渐显，最终与菜单按钮保持左侧对齐。

动画控制器在页面状态创建时启动，因此每次主页状态重新创建都会播放一次。

## 五、功能模块名称

工具注册表中文章工具名称由“文章内容”改为“Wiki”。
工具网格中的名称样式调整为 `FontWeight.w700` 和深色文字，与分类导航栏使用的灰色普通文字区分。

## 六、文件变更

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `lib/features/home/view/home_page.dart` | 修改 | 状态栏同步、移除搜索框、增加搜索入口、增加标题动画 |
| `lib/features/home/view/search_page.dart` | 新增 | 功能搜索页 |
| `lib/features/home/viewmodel/home_viewmodel.dart` | 修改 | 增加搜索关键词与连续匹配 Provider |
| `lib/features/home/data/tool_registry.dart` | 修改 | 增加搜索路由、将文章工具改名为 Wiki |
| `lib/features/home/view/widgets/tool_grid.dart` | 修改 | 工具名称改为加粗深色样式 |
| `lib/core/constants/app_constants.dart` | 修改 | 应用名称改为 Guoxiang LazyBox |
| `lib/core/theme/app_theme.dart` | 修改 | 补充明暗主题状态栏样式 |
| `lib/app/app.dart` | 修改 | 使用常量作为应用标题 |
| `test/home_smoke_test.dart` | 修改 | 适配主页动画结束后的“主页”与 Wiki 文案 |
| `test/search_page_test.dart` | 新增 | 验证自动搜索和空结果状态 |

## 七、后期扩展指引

- 可增加搜索结果高亮、搜索历史和键盘快捷键；
- 工具数量明显增加后，可将搜索数据拆到独立的 SearchRepository；
- 标题动画可抽取为通用品牌启动组件，供其他页面复用；
- 如果需要“首次安装只播放一次”，可用 `shared_preferences` 保存播放标记；
- 状态栏样式可继续统一到全局页面壳组件，避免每个页面重复配置。

## 八、Android 测试包构建脚本

为方便后续本地修改后快速生成安装包，在项目根目录新增 `demo` 文件夹，并加入
`demo/build_android.ps1`。执行该脚本即可完成 Android release APK 构建，最终产物会
固定复制到：

`demo/demo1-android-release.apk`

脚本执行流程如下：

1. 自动根据脚本位置定位 Flutter 项目根目录；
2. 检查 `flutter` 命令和 `pubspec.yaml` 是否可用；
3. 默认执行 `flutter pub get` 获取项目依赖；
4. 执行 `flutter build apk --release` 构建通用 Android 安装包；
5. 将 `build/app/outputs/flutter-apk/app-release.apk` 复制到 `demo` 目录。

在 PowerShell 中从 `demo` 目录执行：

```powershell
.\build_android.ps1
```

如果依赖已经准备完成，也可以跳过依赖获取步骤：

```powershell
.\build_android.ps1 -SkipPubGet
```

该脚本只生成通用 APK，便于在不同 Android 测试设备上直接安装。后续如需减小包体积，
可以再增加按 CPU 架构拆分 APK 的构建参数。
