# 更新文档（2026-09-21）

> 对应 `doc/requirements/target-Sep-21.md`，记录主页标题动画、Wiki 阅读交互、
> 登录提示和 Markdown 编辑体验的更新。

## 一、本次迭代概览

| 需求 | 状态 | 说明 |
| --- | --- | --- |
| 标题动画停留时间 | 已完成 | 首次显示 1.5 秒后开始动画 |
| GuoXiang 收缩点阵 | 已完成 | 最终四点横向并排，不再使用 2×2 排列 |
| 关于页名称 | 已完成 | 仅关于页显示名称改为 BusyBox |
| Wiki 正文复制 | 已完成 | Markdown 正文可选择并使用系统复制菜单 |
| 代码块复制 | 已完成 | 长按围栏代码块复制代码并显示“代码已复制” |
| 图片查看与分享 | 已完成 | 点击图片进入全屏页，可拖动、缩放并调用系统分享 |
| 章节分割线 | 已完成 | 显式使用 1 像素分割线，避免继承全局粗线样式 |
| 忘记密码提示 | 已完成 | 点击“忘记密码”显示“请联系管理员！”三秒提示 |
| Markdown 实时预览 | 已完成 | 正文编辑卡片同时展示源码输入与实时渲染结果 |
| 列表自动续写 | 已完成 | 有序和无序列表按回车后自动生成下一项前缀 |

## 二、主页与关于页

保留用户在 `home_page.dart` 中自行设置的 `GuoXiang BusyBox` 字体、字号、字重、
字距和文字内容，只修改动画时序与点阵终点：标题停留时间由 2 秒调整为 1.5 秒，
四个收缩点最终停在同一水平线上。

应用内部名称常量仍为 `GuoXiang BusyBox`，平台显示名仍为 `BusyBox`；本次只将
“关于 App”页面的大标题改为 `BusyBox`，不影响其他页面和平台配置。

## 三、Wiki 阅读体验

`MarkdownView` 继续作为文章阅读和投稿预览的统一渲染入口，并增加以下能力：

- `MarkdownBody.selectable` 开启正文选择，可使用平台原生复制菜单；
- 围栏代码块由共享组件分段识别，长按后写入系统剪贴板；
- Markdown 图片拥有稳定点击区域，加载失败时显示占位图标；
- 点击图片进入 `FullscreenImageViewer`，使用 `InteractiveViewer` 支持拖动和
  0.5～5 倍缩放；
- 全屏页的分享按钮通过系统分享面板分享图片 URI；
- 相对图片地址继续自动拼接知识库服务地址。

章节卡片中的 `Divider` 显式设置 `thickness: 1`，不再继承应用主题中用于页面分区的
粗分割线厚度。

## 四、登录与 Markdown 编辑

登录页将停用文案“忘记密码？（功能暂不实现）”改为可点击的“忘记密码”。点击后显示
SnackBar“请联系管理员！”，三秒后自动消失。

Description、Causes、Solutions 和 Review 卡片改为上下分区：上方输入 Markdown
源码，下方随 Riverpod 草稿状态实时渲染预览。Question 仍使用普通文本输入，关键词和
总览步骤保持原有结构。

新增 `MarkdownListInputFormatter`：

- 在 `1. 第一项` 后按回车，自动补充 `2. `；
- 在 `- 第一项`、`* 第一项` 或 `+ 第一项` 后按回车，沿用当前无序列表标记；
- 普通文本回车不做转换；
- 最终总览编辑框也复用同一格式化器。

## 五、依赖变更

新增 `share_plus ^13.3.0`，用于调用 Android、iOS、macOS、Windows、Linux 和 Web
可用的系统分享能力。依赖通过本机 HTTP/HTTPS 代理获取，`flutter pub get` 已同步更新
锁文件及桌面平台插件注册文件。

## 六、测试与验证

新增或更新测试覆盖：

- 有序列表、无序列表和普通文本的回车行为；
- Markdown 正文可选择、代码块长按复制；
- 图片点击进入包含缩放控件和分享按钮的全屏页；
- 忘记密码提示；
- Markdown 正文实时预览；
- 关于页显示短名称 BusyBox。

验证命令：

```text
flutter analyze
flutter test
git diff --check
```

验证结果：

- `flutter analyze`：通过，未发现问题；
- `flutter test`：通过，共 63 项测试；
- `git diff --check`：通过，未发现空白字符错误。

## 七、主要文件

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `lib/shared/widgets/markdown_view.dart` | 修改 | 正文选择、代码复制与图片入口 |
| `lib/shared/widgets/fullscreen_image_viewer.dart` | 新增 | 图片缩放与系统分享 |
| `lib/features/article/view/widgets/markdown_list_input_formatter.dart` | 新增 | Markdown 列表自动续写 |
| `lib/features/article/view/article_create_page.dart` | 修改 | 实时预览及格式化器接入 |
| `lib/features/auth/view/login_page.dart` | 修改 | 忘记密码提示 |
| `lib/features/home/view/home_page.dart` | 修改 | 动画等待时间与横向点阵 |
| `lib/features/about/view/about_page.dart` | 修改 | 关于页短名称 |
| `pubspec.yaml` | 修改 | 增加 `share_plus` |

## 八、后期扩展

- 下载并缓存原始图片后，以图片文件而非 URI 分享；
- 增加代码语言识别、语法高亮和显式复制按钮；
- 列表编辑支持空列表项再次回车退出列表，以及任务清单自动续写；
- 为实时预览增加源码/预览比例调整和横屏双栏布局。
