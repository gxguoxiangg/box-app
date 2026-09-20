# 工具盒（demo1）

一个基于 **Flutter + MVVM + Riverpod + go_router** 的工具集合应用。

## 功能

- **主页（工具盒）**：顶部栏（菜单按钮 + 自定义字体品牌动画 + 搜索图标）、分类导航栏、工具按钮网格；
- **侧边栏**：关于 App、软件更新、全局设置入口；
- **全局设置 → 深色模式**：明亮 / 黑暗主题切换，持久化保存；
- **Wiki 知识库**：目录首页支持条目列表、乱序关键词筛选和服务端搜索；点击条目后进入四章内容阅读页，支持目录定位；
- **Wiki 投稿**：账号登录、连续失败临时锁定、1 小时内存会话、七步卡片编辑器、Markdown 快捷工具栏、相机图片上传、关键词多选、投稿预览与确认；
- **网络信息**：当前连接状态（Wi-Fi / 移动数据 / 无连接）、设备网络详情（IP / 网关等）、
  网站连通延迟测试（每行 3 卡片）、网速测试（内嵌 test.ustc.edu.cn）。

> 迭代说明见 `doc/changelog/`，本次更新见 `doc/changelog/update-Sep-18.md`。

## 技术栈

| 层 | 说明 |
| --- | --- |
| UI | Flutter Widget |
| 状态管理 | flutter_riverpod（Notifier / AsyncNotifier） |
| 路由 | go_router（声明式路由，支持 Web 深链） |
| 网络 | http（封装于 core/network） |
| 架构 | MVVM：View（widgets）⇄ ViewModel（providers）⇄ Repository（data）⇄ Model |

## 目录结构

```
lib/
├── main.dart                     # 入口：ProviderScope + App
├── app/
│   ├── app.dart                  # 根组件（MaterialApp.router）
│   └── router/app_router.dart    # go_router 路由表
├── core/
│   ├── constants/app_constants.dart   # 全局常量（API 地址等）
│   ├── theme/app_theme.dart           # 主题
│   └── network/                       # ApiClient 封装与依赖注入
├── features/
│   ├── home/                     # 主页工具盒模块
│   │   ├── models/               # ToolItem / ToolCategory
│   │   ├── data/tool_registry.dart    # 工具注册表
│   │   ├── viewmodel/            # HomeViewModel
│   │   └── view/                 # HomePage 及子组件
│   ├── article/                  # Wiki 知识库模块
│   │   ├── models/               # Article / ArticleDraft / 投稿响应
│   │   ├── data/                 # 阅读与投稿 Repository
│   │   ├── viewmodel/            # 加载 / 搜索 / 草稿 ViewModel
│   │   └── view/                 # Wiki 首页 / 阅读页 / 七步投稿编辑器
│   ├── auth/                     # Wiki 登录、失败锁定和内存会话
│   ├── network/                  # 网络信息模块（连接状态/详情/延迟/网速测试）
│   ├── settings/                 # 全局设置（深色模式已实现）
│   ├── update/                   # 软件更新（占位）
│   └── about/                    # 关于 App
└── shared/
    └── widgets/                  # AppDrawer / MarkdownView 等共享组件
```

## 后期新增功能指南

1. 新建 `lib/features/<功能名>/` 模块，按 `models / data / viewmodel / view` 分层；
2. 在 `features/home/data/tool_registry.dart` 的 `AppRoutes` 中定义路由路径；
3. 在 `app/router/app_router.dart` 注册对应 `GoRoute`；
4. 在 `toolRegistryProvider` 中登记工具按钮（图标 + 名称 + 分类 + 路由）。

## 运行

```bash
flutter pub get
flutter run        # 选择可用设备（Windows / Chrome 等）
```

## 测试

```bash
flutter analyze    # 静态分析
flutter test       # 单元 + 组件测试（含 Mock 网络）
```
