# 更新文档（2026-09-18）

> 对应 `doc/requirements/target-Sep-18.md`，记录主页品牌动画、Wiki 关键词乱序、
> 登录认证与条目投稿功能的完整实现。

## 一、本次迭代概览

| 需求 | 状态 | 说明 |
| --- | --- | --- |
| 主页动画延迟 | ✅ 已完成 | 主页进入后等待 1 秒，再播放品牌动画 |
| 品牌字体 | ✅ 已完成 | GuoXiang 使用 Shadows Into Light，LazyBox 使用 Kaushan Script |
| GuoXiang 收缩效果 | ✅ 已完成 | 文本从水平与垂直方向同步收缩，最终汇聚为居中的四个点 |
| Wiki 关键词乱序 | ✅ 已完成 | 每次进入 Wiki 时重新打乱关键词，并避免随机结果与旧顺序完全相同 |
| Wiki 登录 | ✅ 已完成 | 表单 POST 登录、错误提示、连续失败锁定和一小时内存会话 |
| 条目编辑器 | ✅ 已完成 | 按需求实际列出的 7 个步骤实现左右滑动卡片编辑器 |
| Markdown 工具栏 | ✅ 已完成 | 支持加粗、代码块、有序列表、无序列表与相机按钮 |
| 图片上传 | ✅ 已完成 | 相机拍摄后先上传图片，再将图片 ID 和 Markdown 地址加入草稿 |
| 关键词多选 | ✅ 已完成 | 复用全部关键词接口并支持多选 |
| 总览与投稿 | ✅ 已完成 | Markdown 预览和直接编辑、提交/删除二次确认、成功后返回 Wiki |

需求文字写“总共 6 张卡片”，但随后明确列出 Question、Description、Causes、
Solutions、Reviews、Keywords、Commit 共 7 项。本次按实际列出的 7 个步骤实现，
避免遗漏总览或任一正文小节。

## 二、主页品牌动画

`_AnimatedHomeTitle` 现在使用可取消的 `Timer` 延迟一秒启动，组件销毁时会取消
定时器，避免测试或快速离开页面时留下异步任务。动画阶段如下：

1. `GuoXiang` 使用 `resource/font/ShadowsIntoLight-Regular.ttf`；
2. `LazyBox` 使用 `resource/font/KaushanScript-Regular.ttf`；
3. GuoXiang 在横向和纵向同时缩小；
4. 四个点分别从四个方向向中心移动，形成居中的 2×2 点阵；
5. LazyBox 淡出后显示“主页”。

两个字体已在 `pubspec.yaml` 的 `flutter.fonts` 中注册。

## 三、Wiki 关键词乱序

`ArticleKeywordsNotifier.shuffle()` 负责关键词乱序。Wiki 页面每次进入时主动调用，
首次异步加载完成后也会再执行一次。若随机结果恰好与原列表完全相同，控制器会旋转
一个位置，保证用户每次进入时不会继续看到同一顺序。

## 四、登录与认证

### 4.1 API

登录请求严格按接口文档发送：

```text
POST /api/v1/auth/login
Content-Type: application/x-www-form-urlencoded
```

`AuthRepository` 只负责认证数据访问，`AuthController` 负责页面状态和失败计数。
接口返回的 `access_token` 为空时视为响应格式错误。

### 4.2 失败锁定

- 401 响应显示红色文字：`ⓘ 账号或密码错误。请再试一次`；
- 网络错误和服务端错误不会累计为密码错误；
- 连续第 6 次错误时满足“超过 5 次”，登录入口锁定 15 分钟；
- 锁定计时器在 Provider 销毁时取消。

### 4.3 会话生命周期

登录成功后 Token 只存入 `authSessionProvider` 的内存状态，不写入
`shared_preferences` 或文件。App 侧固定在一小时后清除会话；强制退出应用后内存状态
自然丢失。投稿接口返回 401 时也会立即清除会话并要求重新登录。

## 五、七步条目编辑器

新增路由 `/article/create` 和 `ArticleCreatePage`，包含以下卡片：

1. 问题标题；
2. 具体描述；
3. 产生原因；
4. 解决方案；
5. 复盘；
6. 关键字；
7. 总览。

页面提供进度条、页码和左右箭头，也支持手势左右滑动。文字输入框聚焦后显示长圆角
Markdown 工具栏，可插入加粗、围栏代码块、有序列表和无序列表语法。

关键词页复用 `/api/v1/all-keywords`，使用 `FilterChip` 多选。总览页把结构化字段生成
Markdown 文章，同时允许直接编辑；编辑结果会按固定标题重新解析回草稿字段，因此最终
提交内容和总览保持一致。

## 六、相机与投稿接口

新增 Flutter 官方 `image_picker ^1.2.3`，用于打开系统相机并通过 `XFile` 读取图片
字节。采用字节上传而不是依赖本地文件路径，以兼容 Android、iOS 和 Web。桌面平台或
设备不支持相机时显示提示，不让异常中断编辑流程。

图片和投稿请求顺序：

```text
POST /api/v1/images/upload  (multipart/form-data + Bearer Token)
POST /api/v1/push/item      (application/json + Bearer Token)
```

投稿固定追加到当前默认文章 `article_id=1`。草稿首次创建时生成稳定的
`external_key`，网络失败重试时不会换 key，降低重复投稿风险。提交内容包含五个正文
字段、Markdown 关键词、规范化关键词列表、已上传图片引用和空代码块列表。

Android 最低版本随 `image_picker 1.2.x` 调整为 API 24；iOS 增加相机用途说明。
Flutter 自动更新了 Linux、macOS 和 Windows 的插件注册文件。

## 七、确认和完成行为

- 点击提交按钮弹出“确认提交？”；
- 投稿成功显示“提交成功”和条目 ID，刷新文章/关键词 Provider 后返回 Wiki 首页；
- 投稿失败显示后端或网络错误，并停留在当前页面；
- 点击删除或关闭弹出“删除草稿？”；
- 删除确认后清空内存草稿、显示“草稿已删除”并返回 Wiki 首页。

## 八、主要文件变更

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `lib/features/auth/` | 新增 | 登录模型、Repository、ViewModel 与页面 |
| `lib/features/article/models/article_draft.dart` | 新增 | 草稿、图片引用、Markdown/JSON 转换 |
| `lib/features/article/models/article_submission.dart` | 新增 | 投稿响应模型 |
| `lib/features/article/data/article_submission_repository.dart` | 新增 | 图片上传和条目投稿 |
| `lib/features/article/viewmodel/article_draft_viewmodel.dart` | 新增 | 草稿、上传、提交状态管理 |
| `lib/features/article/view/article_create_page.dart` | 新增 | 七步卡片编辑器 |
| `lib/core/network/api_client.dart` | 修改 | 增加表单、JSON 与 multipart POST 支持 |
| `lib/features/home/view/home_page.dart` | 修改 | 一秒延迟、自定义字体和四点收缩动画 |
| `lib/features/article/viewmodel/article_viewmodel.dart` | 修改 | 关键词进入时乱序 |
| `lib/shared/widgets/markdown_view.dart` | 修改 | 相对图片路径自动拼接知识库服务地址 |
| `pubspec.yaml` | 修改 | 注册字体并增加 image_picker |
| `android/app/build.gradle.kts` | 修改 | Android minSdk 调整为 24 |
| `ios/Runner/Info.plist` | 修改 | 增加相机用途说明 |
| `README.md`、`ai/prompt.md` | 修改 | 同步现有功能、架构与依赖说明 |

## 九、测试与验证

新增测试覆盖：

- 登录表单协议和一小时会话；
- 连续第 6 次错误触发 15 分钟锁定；
- 指定红色错误提示；
- 草稿 Markdown 总览回写和投稿 JSON；
- Bearer Token 与 `/push/item` 请求；
- 七步编辑器进入可编辑总览。

最终验证结果：

```text
flutter analyze  -> No issues found
flutter test     -> 47 tests passed
git diff --check -> passed
```

全部网络测试使用 `MockClient`，不会请求真实知识库服务。

## 十、后期扩展指引

- 将草稿存入本地数据库，支持应用异常退出后的草稿恢复；
- 增加图片缩略图、删除和失败重传，减少服务端孤立图片；
- 后端支持多文章后，在投稿页增加目标文章选择；
- 后端提供 Refresh Token 后，可在认证层增加刷新流程；
- 增加用户主动退出登录入口和剩余会话时长提示；
- 为 Markdown 总览编辑增加标题结构校验和差异提示。
