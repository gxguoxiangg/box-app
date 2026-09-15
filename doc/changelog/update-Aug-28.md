# 更新文档（28 Aug）

> 对应 `更新需求28Aug.md` 的需求，记录「文章显示功能模块」升级的详细更改与说明。

---

## 一、本次迭代概览

| 需求 | 状态 | 说明 |
| --- | --- | --- |
| 按 `backend-doc.md` 的 API 概览解析数据呈现内容 | ✅ 已完成 | 后端从 `:9001/api/article/` 切换为 `:8000/api/v1/` 知识库接口 |
| 页面布局：标题 + 作者/更新时间 + 四章卡片 + 圆形添加按钮 | ✅ 已完成 | 一屏一条目，四章（Description/Causes/Solutions/Review）卡片化 |
| 正确解析 Markdown（含代码框/表格/图片/链接） | ✅ 已完成 | 引入 Flutter 官方 `flutter_markdown`（GFM 扩展）替换自研渲染器 |
| 目录按钮 + 侧边栏（无限下拉、点击跳转） | ✅ 已完成 | 右侧抽屉目录，按标题点击跳转到对应卡片 |

**与需求方的交互确认**（本次开发前沟通确定的方向）：

| 决策点 | 结论 |
| --- | --- |
| 主内容浏览方式 | 左右滑动卡片（复用 PageView），一屏一条目 |
| 底部圆形「添加」按钮 | 占位（点击提示「功能待定」，后期再定） |
| 搜索框 | 服务端搜索（`/items?q=`），适配内容增长；点击结果进入详情页 |
| Markdown 渲染 | 引入 `flutter_markdown` 官方包 |

---

## 二、后端数据契约切换

### 2.1 API 地址变更

| 项 | 旧 | 新 |
| --- | --- | --- |
| 基础地址 | `http://159.75.86.98:9001` | `http://159.75.86.98:8000` |
| 前缀 | `/api/article/{id}` | `/api/v1` |
| 文章数据 | 单篇 `{ id, title, level, content }` | 文章嵌套条目（`/articles/{id}`） |

> 常量集中在 `lib/core/constants/app_constants.dart`：新增 `kbApiBaseUrl`、
> `kbApiPrefix`、`defaultArticleId`，移除旧的 `apiBaseUrl` / `articleEndpoint` /
> `articleTotal`。

### 2.2 涉及的接口

| 接口 | 用途 | 对应仓库方法 |
| --- | --- | --- |
| `GET /api/v1/articles/{id}` | 文章详情（嵌套全部条目） | `fetchArticle` |
| `GET /api/v1/items/{id}` | 单条目详情（含四章正文） | `fetchItem` |
| `GET /api/v1/items?q=` | 服务端搜索（返回摘要） | `searchItems` |

### 2.3 字段与四章正文的映射

| 页面章节 | 后端字段 | 说明 |
| --- | --- | --- |
| 01 Description | `description` | 问题描述 |
| 02 Causes | `causes` | 原因分析 |
| 03 Solutions | `solutions` | 解决方案 |
| 04 Review | `review` | 参考 / 回顾 |

- 四个字段均为 **Markdown 文本**，且**可能为 null**（如 `causes`、`review` 常为空）；
  渲染时对 null 章节展示「暂无内容」占位，保证四章结构稳定。
- 标题取条目的 `question`，展示时剥离「Q - 」前缀（模型层提供 `displayTitle`）。

---

## 三、代码改动明细

### 3.1 核心层

| 文件 | 改动 | 说明 |
| --- | --- | --- |
| `lib/core/constants/app_constants.dart` | 修改 | 替换为知识库后端常量 |
| `lib/core/network/api_client.dart` | 修改 | ① `baseUrl` 可配置（支持注入 Mock）；② 新增 `getJson` 返回**完整 JSON**（知识库后端无 `{success,data}` 包装，不再做 data 解包） |

### 3.2 数据模型（`lib/features/article/models/article.dart`，重写）

| 类 | 对应 | 字段要点 |
| --- | --- | --- |
| `Article` | 文章 | `id/title/sourceFile/frontmatterDate/updatedAt/tags/itemCount/items` |
| `ArticleItem` | 条目（Q&A） | `id/articleId/position/question` + 四章正文 + `keywords`；派生 `displayTitle` |
| `ArticleItemSummary` | 搜索摘要 | `id/articleId/position/question/hasImages/hasCode` |

### 3.3 数据层（`article_repository.dart`，重写）

- `fetchArticle(id)`：一次请求拿整篇（69 条），供「滑动卡片 + 目录」使用，避免逐条请求；
- `fetchItem(id)`：单条详情，供搜索结果点击进入详情页；
- `searchItems(query)`：服务端搜索，返回摘要列表。

### 3.4 ViewModel（`article_viewmodel.dart`，重写）

| Provider | 类型 | 职责 |
| --- | --- | --- |
| `articleProvider` | `AsyncNotifier<Article>` | 加载整篇文章（loading/error/data） |
| `articleItemProvider` | `FutureProvider.family<ArticleItem, int>` | 按 ID 加载单条详情 |
| `articleSearchControllerProvider` | `Notifier<String>` | 关键词状态 + **300ms 防抖**触发搜索 |
| `articleSearchResultProvider` | `AsyncNotifier<List<ArticleItemSummary>>` | 搜索结果；带**请求序号**丢弃过期响应 |

### 3.5 视图层

| 文件 | 改动 | 说明 |
| --- | --- | --- |
| `view/article_list_page.dart` | 重写 | 浏览页：滑动卡片 + 目录侧边栏 + 搜索 + 占位添加按钮 |
| `view/item_detail_page.dart` | 新增 | 条目详情页（搜索结果点击进入） |
| `view/widgets/item_content.dart` | 新增 | **共享组件**：标题 + 作者/更新时间 + 四章卡片（浏览页与详情页复用） |
| `view/widgets/article_card.dart` | 重写 | 滑动卡片单页（内部可滚动，底部留白避让 FAB） |
| `shared/widgets/markdown_view.dart` | 重写 | 基于 `flutter_markdown` 的 Markdown 渲染 |

### 3.6 路由与注册

| 文件 | 改动 |
| --- | --- |
| `features/home/data/tool_registry.dart` | 新增 `AppRoutes.articleItemDetail` 及 `articleItemDetailPath(id)` |
| `app/router/app_router.dart` | 新增条目详情路由 `GoRoute`（路径参数 `:id`） |

---

## 四、关键设计说明

### 4.1 浏览 vs 搜索双模式

页面根据搜索关键词是否为空，切换两种展示：

- **浏览模式**（关键词为空）：`PageView` 左右滑动 69 个条目，右下角显示「添加」FAB；
- **搜索模式**（关键词非空）：展示服务端搜索结果列表，点结果进入详情页（FAB 隐藏）。

这样「目录」只服务于浏览模式（跳转到对应卡片），而搜索结果走「直达详情页」的路径，
二者职责清晰、互不干扰。

### 4.2 服务端搜索 + 防抖 + 过期响应丢弃

- 输入停止 **300ms** 后触发一次 `/items?q=`，避免每敲一个字发一次请求；
- 结果加载器用 `_requestSeq` 序号标记请求，**仅应用最新一次**的结果，防止慢请求覆盖新结果；
- 关键词清空时立即清空结果并回到浏览模式。

### 4.3 Markdown 渲染（`flutter_markdown`）

- 默认使用 `ExtensionSet.gitHubFlavored`，天然支持**围栏代码块**、**表格**、
  图片、链接、行内代码等（实测源码确认默认扩展集含 GFM）；
- 自定义样式：正文行高 1.6、行内代码橙色高亮、代码块浅灰圆角卡片；
- 图片通过 `sizedImageBuilder` 以 `fitWidth` 限制宽度，避免超宽图片横向溢出；
- 链接点击用 `url_launcher` 唤起系统浏览器。

### 4.4 目录侧边栏

- 顶栏「目录」按钮（`Icons.toc`）打开**右侧抽屉**（`endDrawer`）；
- 抽屉内 `ListView.builder` 无限下拉，按 `position` 序号 + 标题展示全部条目；
- 点击某项 → 关闭抽屉 → `PageController.jumpToPage(index)` 跳转到对应卡片。

### 4.5 作者 / 最后更新

- **作者**：后端暂未返回，展示「作者：待定」占位，接口补充后替换（`item_content.dart`）；
- **最后更新**：取文章级 `updated_at`，格式化为 `yyyy-MM-dd`；详情页无该字段时显示「—」。

---

## 五、依赖变更

| 依赖 | 版本 | 用途 |
| --- | --- | --- |
| `flutter_markdown` | ^0.7.7+1 | Markdown 渲染（代码块/表格/图片/链接），Flutter 官方维护 |
| （传递依赖）`markdown` | — | `flutter_markdown` 的底层 Markdown 解析器 |

---

## 六、测试

`flutter analyze` 0 问题；`flutter test` 全量通过（共 **34** 项）：

| 测试文件 | 覆盖内容 |
| --- | --- |
| `test/article_test.dart`（重写） | 模型解析（文章/条目/摘要）、可空字段、`displayTitle` 前缀剥离 |
| `test/article_repository_test.dart`（新增） | 仓库三方法：请求路径 + 解析（MockClient 离线模拟） |
| `test/article_page_test.dart`（重写） | 浏览模式渲染、目录侧边栏打开、服务端搜索触发与结果展示 |
| `test/item_detail_page_test.dart`（新增） | 详情页按 ID 加载并展示标题与章节 |
| 既有测试 | 主页 / 侧边栏 / 主题 / 网络模块等，未受影响全部通过 |

**Mock 说明**：所有文章相关测试通过 `apiClientProvider.overrideWithValue` 注入
`MockClient`，模拟 `/api/v1/...` 响应，不依赖真实网络，可离线稳定运行。

---

## 七、后期扩展指引

1. **补充作者字段**：后端返回作者后，在 `ItemContent` 的元信息行替换「待定」占位；
2. **多篇文章**：将 `defaultArticleId` 的「固定加载」改为「文章列表页 → 用户选择」，
   复用 `/articles` 列表接口 + `articleProvider` 增加 `family` 化；
3. **目录高亮当前项**：监听 `PageController` 的页码，同步高亮目录当前条目；
4. **搜索分页**：`/items?q=` 返回 `total/page/page_size`，可在结果列表底部加「加载更多」；
5. **代码块语法高亮**：为 `MarkdownView` 增加语言高亮（如 `highlight` 包），
   或在 `sizedImageBuilder` 同级的 `builders` 中自定义代码块渲染；
6. **占位「添加」按钮落地**：对接 `POST /api/v1/push/item`（需 JWT 登录），
   或先跳转「新增条目」页面。
