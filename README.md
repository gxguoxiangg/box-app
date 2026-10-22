# BusyBox（demo1）

示例图：

![home_page](C:\Users\46823\Desktop\Dart\Flutter\demo1\example\home_page.jpg)



![wiki_page](C:\Users\46823\Desktop\Dart\Flutter\demo1\example\wiki_page.jpg)



![wiki_page2](C:\Users\46823\Desktop\Dart\Flutter\demo1\example\wiki_page2.jpg)





一个基于 **Flutter + MVVM + Riverpod + go_router** 的工具集合应用。

## 功能

- **主页（工具盒）**：菜单按钮、首次进入品牌动画、个人中心入口、网络摘要、可自定义的常用工具；全部工具动态展示未固定项，Wiki 移出常用区后仍可打开；
- **侧边栏**：设置、统计（待开发）、关于APP；
- **自定义常用工具**：点击主页「自定义」后可增减最多六项常用工具，操作实时反映到主页并保存在本地；
- **界面配色模板**：主页、侧边栏、自定义页共用 `BusyBoxPalette`，通过 `ThemeExtension` 支持亮色与深色，为以后切换配色预留入口；
- **全局设置 → 深色模式**：明亮 / 黑暗主题切换，持久化保存；
- **Wiki 知识库**：新版卡片目录、带真实条目计数的关键词筛选和服务端搜索；阅读页支持四章正文、左右翻页、目录、代码语言标签及点击/长按复制，以及图片全屏缩放和系统分享；
- **Wiki 投稿**：账号登录、连续失败临时锁定、1 小时内存会话、七步所见即所得编辑器、列表自动续写、相机图片上传、关键词多选；总览默认使用阅读页样式预览，可切回编辑并确认提交；
- **网络信息**：当前连接状态（Wi-Fi / 移动数据 / 无连接）、设备网络详情（IP / 网关等）、
  网站连通延迟测试（每行 3 卡片）、网速测试（内嵌 test.ustc.edu.cn）。

> 迭代说明见 `doc/changelog/`，本次更新见 [Oct-15 更新说明](doc/changelog/update-Oct-15.md)。Wiki 参考稿位于 `doc/ui/wiki/`。

Sep-30 界面更新：主页与自定义页采用圆角卡片、轻阴影和圆形操作按钮，侧边栏使用本地原子图标。保留品牌标题动画、工具三列布局和常用图标蓝色。网络字段长按复制；柱条仅表示连接状态动效，非实时流量，连接变化时自动刷新摘要，断开后停播。

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
│   ├── theme/                         # AppTheme + BusyBoxPalette 配色模板
│   └── network/                       # ApiClient 封装与依赖注入
├── features/
│   ├── home/                     # 主页工具盒模块
│   │   ├── models/               # 工具描述模型
│   │   ├── data/                 # 工具目录与路由常量
│   │   ├── viewmodel/            # 网络摘要与常用工具持久化
│   │   └── view/                 # HomePage、自定义页及子组件
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
4. 根据展示位置在 `home_tool_options.dart` / `home_catalog.dart` 登记工具及路由；旧搜索页仍使用 `toolRegistryProvider`。

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

## 神机（IADB）资产查询

- 在主页常用工具、全部工具或功能搜索中打开「神机」，使用独立的神机账号登录。
- 支持关键词搜索、每页 20 条分页、资产卡片、关联详情、IP/MAC 点击复制；命中记录另列展示，保留未关联资产的记录。
- 默认服务为 `http://159.75.86.98:10001`，可通过 `--dart-define=IADB_API_BASE_URL=服务地址` 覆盖。账号密码由用户输入，令牌只保存在当前进程内存中。
- 本次不包含排序、导出、Ping、SSH、测速和索引管理。浏览器部署需要后端允许 CORS；HTTPS 页面访问 HTTP 服务还受浏览器混合内容限制。
- 详细变更见 [Oct-15 更新说明](doc/changelog/update-Oct-15.md)。

### Oct-18 显示更新

神机资产卡片支持父级部门/位置路径、分钟级创建时间，并调整资产类型、厂商和描述的位置；主页、Wiki、神机顶栏统一标题和副标题字号，标题加粗。详见 [Oct-18 更新说明](doc/changelog/update-Oct-18.md)。

### Oct-19 神机层级修复

修复实际 API 只返回 parent_id 导致父级部门/位置不显示的问题，通过已有单条查询接口补全名称；厂商移回标题右侧标签。详见 [Oct-19 修复说明](doc/changelog/update-Oct-19.md)。

最新字段位置：神机卡片右上显示 vendor，标题右侧标签显示 description；department 为空且接口返回 department_parent 时仅显示父级名称。

### Oct-20 字段调整与安全检查

神机卡片右上显示 description，标题右侧标签显示 vendor。已完成密码专项静态检查，发现本地文档中存在明文凭据，详见 [更新说明](doc/changelog/update-Oct-20.md) 和 [安全检查报告](doc/review/2026-10-20-credentials.md)。

### Oct-21 网络计算器

新增网络计算器入口，可从全部工具、常用工具或功能搜索进入。子网掩码页支持四段 IPv4 输入、/1–/32 滑块及加减按钮、实时计算掩码/网络号/主机容量/可用范围、复制结果；支持明暗主题与窄屏。/31 按点对点链路、/32 按单主机计算，不显示虚构广播地址。POE、带宽入口提示“暂未开放”。详细进度见 [Oct-21 更新说明](doc/changelog/update-Oct-21.md)。神机卡片 asset_type 下方大标题显示 asset.vendor（18px），旁边显示 asset.model（16px，空值隐藏），右侧标签显示 asset["权限类别"]（例如“仅绑定”）；空值显示“—”。

### Oct-22 界面更新

神机登录提示改为“请使用神机账户登录”。网络计算器统一标题字体并补充“BusyBox 工具魔盒”副标题，依据 Stitch 更新输入格、CIDR胶囊、滑块、图标底座及紧凑结果卡片，适配明暗主题与字体放大；计算结果标题和 IPv4 标准保持左右同行，主机容量两列共享标签行并按数值基线对齐。计算逻辑保持不变，详见 [Oct-22 更新说明](doc/changelog/update-Oct-22.md)。
