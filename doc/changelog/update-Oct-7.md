# 2026-10-07 主页工具修复与 Wiki 界面更新

## 需求与确认范围

依据 `ai/prompt.md` 和 `doc/requirements/target-Oct-7.md` 实现。经确认：

- Wiki 首页参照 `doc/ui/wiki/wiki_home_page.html`。
- 阅读正文参照 `wiki_article_details_page.html`，保留精简返回/目录栏、添加入口和左右切换文章。
- 投稿页采用独立的 `wiki_add_article_page.html`，保留七步所见即所得编辑流程。
- 本次沿用现有搜索、关键词、认证和投稿接口，不新增分类服务、SQLite 离线草稿或自动同步。作者、日期和数量不使用设计稿示例数据。

## 主页：移出常用区后入口丢失

原“全部工具”固定使用六项占位工具目录，没有包含 Wiki、测网速和神机，也未随常用工具配置变化。因此 Wiki 移出常用区后不再出现在主页。

现由 `unpinnedHomeToolsProvider` 从完整的 `homeToolOptions` 中排除已固定项，主页“全部工具”随配置实时更新：

- 移除 Wiki 后，Wiki 出现在全部工具中，原有跳转保持有效。
- 再次固定 Wiki 后，它从全部工具区移除，避免重复。
- 同一规则适用于其他工具；常用工具的上限和持久化方式不变。

## Wiki 首页

- 统一顶部 Wiki / BusyBox · 知识库标题，保留返回和目录操作。
- 搜索框使用圆角描边，关键词使用胶囊筛选器；关键词旁数量按已加载条目实际计算。
- 列表采用圆角白色/深色卡片，展示标题、关键词及可用的文章级更新时间；长标签在窄屏换行。
- 搜索沿用服务端防抖查询；搜索期间隐藏只适用于目录列表的关键词筛选器，避免点击后结果无变化。
- 新建入口保留登录检查。搜索摘要缺少标签/日期时仅显示接口已有信息。

## Wiki 阅读页

- 正文改为大标题、真实更新时间、关键词和四个独立章节卡片。
- 四章分别显示「问题描述 / 产生原因 / 解决方案 / 审查复盘」及英文标签。
- 接口未返回作者，移除原「作者：待定」占位；没有日期时隐藏更新时间。
- 代码块显示深色底、围栏语言标签及复制按钮；保留长按复制、文本选择、图片全屏等既有交互。
- 阅读页保留从指定条目打开、目录定位、左右翻页，以及按认证状态进入投稿或登录页。

## Wiki 七步投稿

- 采用新标题栏、步骤编号、图标卡片头、上下步文字按钮及滑动提示。
- 正文继续在原位进行富文本编辑，保留格式工具栏和相机图片上传。
- 关键词分为已选标签（可移除）与服务端可选标签（点击加入）；不虚构热门分类，也不增加后端未定义的标签接口。
- 第七步默认显示实际渲染预览，复用阅读页 `ItemContent`；点击「编辑总览」仍可编辑完整 Markdown，再返回预览。
- 切换预览、翻页或提交前读取最新编辑内容，避免编辑器 120ms 防抖尚未触发而遗漏最后输入。
- 保留草稿删除确认、提交确认、无效响应提示和原认证逻辑。草稿仍仅保存在内存中。
- 本次不改变原有标题长度规则，不因设计稿示例的“最多40字”截断既有内容。

## 主要文件

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `lib/features/home/viewmodel/home_pinned_viewmodel.dart` | 修改 | 动态未固定工具 Provider |
| `lib/features/home/view/widgets/home_all_tools.dart` | 修改 | 使用完整未固定目录 |
| `lib/features/home/data/home_catalog.dart` | 修改 | 移除固定列表 Provider，保留工具元数据 |
| `lib/features/article/view/widgets/wiki_theme.dart` | 新增 | Wiki 配色范围、标题栏和标签组件 |
| `lib/features/article/view/article_list_page.dart` | 修改 | 首页卡片、搜索和真实计数筛选 |
| `lib/features/article/view/article_reader_page.dart` | 修改 | 阅读页标题栏与主题 |
| `lib/features/article/view/widgets/item_content.dart` | 修改 | 阅读与投稿预览共用正文 |
| `lib/features/article/view/article_create_page.dart` | 修改 | 七步卡片、标签选择、预览/编辑切换 |
| `lib/shared/widgets/markdown_view.dart` | 修改 | 语言标签、点击复制、可选深色代码块 |
| `test/home_unpinned_tools_test.dart` | 新增 | Wiki 移除、打开、重新固定完整回归 |
| `test/wiki_layout_test.dart` | 新增 | 320 宽明暗正文及缺失元信息处理 |
| Wiki 首页、投稿、Markdown 交互及深色模式测试 | 修改 | 新布局与既有行为回归 |

没有新增第三方依赖，也没有变更接口地址或提交格式。Wiki 外观通过 `WikiTheme` 复用 `BusyBoxPalette`，不覆盖其他页面的主题。

## 验证

- `flutter test --no-pub`：85 项全部通过。
- `flutter analyze --no-pub`：0 个问题。
- `git diff --check`：通过。
- 新增回归覆盖 Wiki 移除/打开/重新固定、真实关键词过滤、360 宽七步编辑与预览、320 宽明暗正文、缺失作者和日期处理。既有代码长按复制测试扩展了按钮复制与语言标签检查。
- 网络相关测试使用 MockClient 或 Provider 注入，不发送真实投稿请求。深色模式旧测试更新为检查实际 Card 的 Material 颜色。

代码更新阶段未构建 APK；随后按要求重新打包，结果见下方。未执行真机安装测试，也未提交或推送 Git。

### APK 重新构建（2026-10-07）

- 检查并执行 `demo/build_android.ps1`，脚本无需修改；依赖获取、Release 构建及复制均成功。
- 安装包：`demo/demo3-android-release.apk`，已覆盖旧文件，包含本次 Oct-7 更新。
- 大小：60,697,101 字节（57.89 MiB）。应用名称 BusyBox，版本 `0.1.0+1`，最低 Android API 24；包含 arm64-v8a、armeabi-v7a 和 x86_64。
- `apksigner verify --verbose` 通过；当前 Release 配置仍使用项目的调试签名，供安装测试。
- 输出文件与原始构建产物 SHA-256 一致：`CE16AA0718E13109484D9E1B15FE6A3CE63A16C38F4B5F4C9DBD1950260FD528`。
- 构建有插件 Kotlin 兼容性及 Cupertino 图标字体提示，未阻止本次构建；没有因提示升级依赖。

## 后期扩展指引

- 新工具统一登记到 `homeToolOptions`，全部工具通过未固定项派生，不再维护另一份静态展示清单。
- Wiki 配色和卡片样式集中在 `WikiTheme`；正文结构集中在 `ItemContent`，投稿预览与阅读页保持一致。
- 作者、分类、离线草稿和同步需要独立的数据设计及接口支持，后续按需求单独实现。
