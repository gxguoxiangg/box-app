# 更新文档（2026-09-16）

> 对应 `doc/requirements/target-Sep-16.md`，记录 Wiki 模块与主页动画更新。

## 一、本次迭代概览

| 需求 | 状态 | 说明 |
| --- | --- | --- |
| Wiki 顶部栏名称 | ✅ 已完成 | Wiki 首页和阅读页统一显示 Wiki 与知识库图标 |
| Wiki 搜索返回 | ✅ 已完成 | 搜索状态下点击页面返回或 Android 返回键，只清空搜索并留在 Wiki 首页 |
| 主页品牌动画 | ✅ 已完成 | GuoXiang 收缩为两个平行黑点后消失，LazyBox 使用不同字体并随后淡出 |
| Wiki 首页目录化 | ✅ 已完成 | 从直接阅读改为条目列表、数量、标签和更新时间布局 |
| 关键词筛选 | ✅ 已完成 | 接入 `/api/v1/all-keywords`，关键词横向滚动并支持筛选 |
| 首页条目进入阅读页 | ✅ 已完成 | 点击条目后进入原有四章内容阅读界面 |
| 当前条目目录定位 | ✅ 已完成 | 从首页或搜索结果进入阅读页时，PageView 和目录抽屉定位到当前条目 |

## 二、Wiki 首页

`ArticleListPage` 现在承担 Wiki 知识库首页职责，页面结构为：

1. 顶部显示返回按钮、Wiki 图标、Wiki 名称和目录按钮；
2. 保留原有服务端搜索框；
3. 增加横向滚动的关键词筛选 Chip，首项为“全部”；
4. 显示当前筛选结果数量；
5. 使用卡片展示条目标题、关键词标签和更新时间；
6. 保留右下角“添加”占位按钮。

条目卡片点击后通过 `AppRoutes.articleItemDetailPath(id)` 进入阅读页。页面会先清空
搜索状态，避免返回 Wiki 首页后仍停留在旧搜索结果。

## 三、搜索返回行为

Wiki 首页增加了显式的搜索状态返回规则：

- 点击顶部返回按钮时，如果搜索框有内容，则清空输入并回到 Wiki 条目列表；
- 搜索框清空后再次点击返回，才离开 Wiki 并返回工具盒主页；
- 使用 Android 系统返回键时，通过 `PopScope` 执行相同规则；
- 清空操作同时更新 `articleSearchControllerProvider` 和页面输入控制器，保证视觉内容与状态一致。

## 四、主页品牌动画

`_AnimatedHomeTitle` 的品牌动画调整为以下顺序：

1. `GuoXiang` 使用偏商务的加粗无衬线样式；
2. 文本沿横向快速收缩，淡出时在原位置显示两个水平并排的黑色圆点；
3. 两个圆点和 `GuoXiang` 整体快速消失；
4. `LazyBox` 使用衬线样式，并在第二阶段渐隐；
5. 最后显示“主页”。

GuoXiang 的动画区间短于 LazyBox，因此会更快完成消失。动画仍由组件生命周期控制，
每次主页组件重新创建时播放一次。

## 五、关键词接口与数据层

新增 `KeywordCollection` 模型和 `ArticleRepository.fetchAllKeywords()`：

```text
GET /api/v1/all-keywords
```

接口返回的 `keywords` 会在模型层去除首尾空白并忽略空字符串。关键词加载由
`articleKeywordsProvider` 管理，筛选条件由 `articleKeywordControllerProvider` 管理，
页面通过 `filteredArticleItemsProvider` 获取最终条目列表，保持 View → ViewModel →
Repository → Model 的数据流方向。

条目卡片的标签来自条目自身的规范化 Markdown 关键词字段。后端关键词总览接口负责
提供筛选器选项，客户端不再自行扫描全部条目推断筛选器内容。

## 六、阅读页与目录定位

新增 `lib/features/article/view/article_reader_page.dart`，将原有 PageView 阅读行为
独立出来：

- 阅读内容仍使用 `ArticleCard` 和 `ItemContent`，四章正文展示方式保持不变；
- 首页点击和搜索结果点击统一进入阅读页；
- `initialItemId` 用于计算当前条目的位置；
- `PageController` 首次加载后跳转到当前条目；
- 目录抽屉高亮当前条目，并自动滚动到当前条目附近；
- 路由仍使用原有 `/article/item/:id`，外部深链不需要改变。

原 `ItemDetailPage` 保留用于兼容既有调用和测试，应用路由中的条目入口统一使用新的
阅读页，从而保证搜索进入后也能使用目录。

## 七、文件变更

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `lib/features/article/models/keyword_collection.dart` | 新增 | 解析全部关键词接口响应 |
| `lib/features/article/models/article.dart` | 修改 | 增加 Markdown 关键词列表解析 |
| `lib/features/article/data/article_repository.dart` | 修改 | 增加 `fetchAllKeywords` |
| `lib/features/article/viewmodel/article_viewmodel.dart` | 修改 | 增加关键词加载、选择和条目筛选 Provider |
| `lib/features/article/view/article_list_page.dart` | 修改 | 改为 Wiki 目录首页，增加筛选和搜索返回处理 |
| `lib/features/article/view/article_reader_page.dart` | 新增 | 从指定条目开始的四章内容阅读页 |
| `lib/features/home/view/home_page.dart` | 修改 | 调整 GuoXiang / LazyBox 品牌动画 |
| `lib/app/router/app_router.dart` | 修改 | 条目路由切换到统一阅读页 |
| `lib/features/home/data/tool_registry.dart` | 修改 | 更新 Wiki 路由注释 |
| `README.md` | 修改 | 更新 Wiki 功能、目录和文档入口 |
| `test/article_test.dart` | 修改 | 增加关键词解析测试 |
| `test/article_repository_test.dart` | 修改 | 增加关键词接口 Mock 测试 |
| `test/article_page_test.dart` | 修改 | 覆盖 Wiki 首页、搜索返回和目录展示 |
| `test/article_reader_page_test.dart` | 新增 | 覆盖当前条目初始定位和目录入口 |

本次没有新增第三方依赖，继续使用项目已有的 Riverpod、go_router 和 http 封装。

## 八、验证结果

已完成以下检查：

- `flutter analyze`：通过，No issues found；
- `flutter test`：通过，40 项测试全部通过；
- `git diff --check`：通过。

网络相关测试均使用 `MockClient`，不会访问真实的知识库接口，适合离线执行。

## 九、后期扩展指引

- 可将条目级 `updated_at` 和关键词结构加入后端摘要接口，进一步丰富首页卡片；
- 可为关键词筛选增加多选模式，目前保持单关键词筛选以减少交互复杂度；
- 可将目录抽屉抽取为共享组件，供其他有序内容模块复用；
- 可使用 `shared_preferences` 保存最后阅读的条目，实现重新打开 Wiki 时恢复位置；
- 可将品牌动画中的字体和时间区间抽到主题或品牌配置中，便于后续视觉调整。
