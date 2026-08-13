# 工具盒（demo1）

一个基于 **Flutter + MVVM + Riverpod + go_router** 的工具集合应用。

## 功能

- **主页（工具盒）**：顶部栏（菜单按钮 + 应用名 + 搜索框）、分类导航栏、工具按钮网格；
- **侧边栏**：关于 App、软件更新、全局设置入口；
- **全局设置 → 深色模式**：明亮 / 黑暗主题切换，持久化保存；
- **文章内容展示**：通过 API 获取 JSON 文章数据，以滑动卡片（PageView）展示，支持按标题搜索过滤；
- **网络信息**：当前连接状态（Wi-Fi / 移动数据 / 无连接）、设备网络详情（IP / 网关等）、
  网站连通延迟测试（每行 3 卡片）、网速测试（内嵌 test.ustc.edu.cn）。

> 迭代说明见 `更新文档.md`。

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
│   ├── article/                  # 文章内容展示模块
│   │   ├── models/               # Article
│   │   ├── data/                 # ArticleRepository
│   │   ├── viewmodel/            # 加载 / 搜索 ViewModel
│   │   └── view/                 # ArticleListPage / ArticleCard
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
