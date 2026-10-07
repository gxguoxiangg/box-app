# 2026-09-30 主页、常用工具自定义页与侧边栏视觉更新

## 需求与已确认方案

- 依据 `ai/prompt.md`、`doc/requirements/target-Sep-30.md` 和 `doc/ui/` 下三份 HTML 设计稿更新。
- 保留本次修改前的 GuoXiang BusyBox 标题动画：首帧显示、停留一秒、文字收缩与渐隐、四圆点和最终「主页」文案的时序及样式均不调整。
- 网络区域三根柱条作为**连接状态装饰动效**，不读取流量、不显示模拟速率，也不代表互联网一定可达。提示明确为「连接状态动效，非实时流量」。
- 网络字段继续**长按复制**，点击不复制；空值「—」不复制。保留 Wi-Fi 接入点 MAC 来源标注及 `XXXX-XXXX-XXXX` 格式。

## 界面变化

### 主页

- 页面主体使用配色模板的页面底色，网络面板及常用工具使用 20 像素圆角和轻阴影。
- 网络字段使用 14 像素圆角，连接状态使用胶囊形徽标；标题旁加入连接动效。
- 常用工具卡片高 96 像素、每行三列，图标保留品牌蓝；自定义入口改为描边胶囊按钮。
- 全部工具从一个带分隔线的面板改为独立的 16 像素圆角卡片，卡片间距 10 像素。
- 正文区块淡入上移；可点击卡片具有水波纹和按压缩放反馈。系统要求减少动画时，新入场及缩放动画停用。

### 自定义常用工具

- 移除「桌面磁贴个性化配置与快捷挂载 / 实时生效」提示横幅。
- 分组使用圆角面板，数量使用胶囊标识；窄屏标题和提示可换行。
- 工具使用圆角卡片、圆形图标底座和圆形加减按钮，「完成」改为胶囊按钮。
- 保留两组固定三列、最多六项、实时保存；已选图标蓝色，未选图标使用主题正文色。
- 标题栏和状态栏保持同色，明暗主题均通过现有 `BusyBoxPalette` 取色。

### 侧边栏

- 使用设计目录提供的 `atom.png`，复制到运行资源目录并通过 Flutter assets 本地加载，无需网络。
- 图片包含白底，按原图显示并裁剪圆角，不对整张图片着色，避免变成实心色块。
- 保留四角圆角、较细「更多」标题、0.5 像素分隔线、设置/统计/关于APP，以及顶部抽屉外侧的暗色遮罩。

## 实现文件

| 文件 | 变化 |
| --- | --- |
| `lib/shared/widgets/busybox_card.dart` | 新增共享卡片、水波纹、按压缩放和正文入场组件 |
| `lib/features/home/view/home_page.dart` | 主体底色、标题栏轻阴影与正文入场 |
| `lib/features/home/view/widgets/home_network_panel.dart` | 圆角网络面板与连接动效入口 |
| `lib/features/home/view/widgets/connection_activity.dart` | 新增连接动效；断开、后台、路由不可见或减少动画时停止 |
| `lib/features/home/view/widgets/home_quick_tools.dart`、`home_all_tools.dart` | 工具卡片与自定义入口样式 |
| `lib/features/home/view/custom_tools_page.dart` | 自定义页分组、卡片和操作按钮 |
| `lib/features/network/data/network_repository.dart` | 新增可选 `NetworkConnectionEvents` 接口，真实仓库提供连接变化通知 |
| `lib/features/home/viewmodel/home_network_viewmodel.dart` | 连接类型变化时重新读取摘要，自动释放订阅；不触发网站延迟测试 |
| `lib/shared/widgets/app_drawer.dart`、`resource/images/atom.png`、`pubspec.yaml` | 侧边栏本地图标与资源登记 |

无新增第三方依赖。网络变化仍通过 Repository → Riverpod → View 分层传递；不支持通知的仓库继续使用原有单次读取。

## 验证

- `flutter test --no-pub`：**81 项全部通过**。
- 覆盖联网播放/断网停止、减少动画与不可见时停播、连接变更刷新与订阅释放、点击不复制/长按复制、320 像素明暗主题布局、360 像素三列与选中配色、工具增减、标题动画时序、侧边栏资源和状态栏遮罩。
- 新增网络相关测试均使用假仓库、内存事件流或模拟平台通道，不依赖真实网络。
- `flutter analyze --no-pub`：**0 个问题**。
- 本次没有重新构建 APK，也未进行真机安装验证；此前生成的 APK 不包含本次更新。

## 后期扩展

- 修改圆角与卡片交互集中调整 `BusyBoxCard`；切换配色仍通过 `BusyBoxPalette`。
- 真实网络速率应新增采样接口与数据模型，不复用装饰柱条作为测量结果。
- HTML 中模拟的系统时钟和底部手势条由设备系统提供，应用不重复绘制。
