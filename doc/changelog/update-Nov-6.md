# Nov-6 网络计算器 UI 校准

## 设计依据
通过 Stitch get_screen/download_file 获取项目 2299265049139915786、页面 b52e17b535f74d9fa3e9b51de5e4c96b 的 HTML 和截图（780×2362）。资源位于 doc/ui/net-calc/Nov-6.html、Nov-6-original.jpg。

## 变更
- 顶栏副标题按稿件显示 BusyBox，灰色加粗。
- 卡片正文复用已安装的 IBM Plex Sans，保留中文系统回退。
- 输入格收紧分隔点间距，显式设置文本行高和内边距。
- 标签页取消额外 Material 点击布局留白，校正卡片上方间距。
- 结果块最小高度52，纵向间距12；保留窄屏和大字体布局。
- ADB 第一轮截图发现按钮、输入格偏大，第二轮缩小加减按钮至32、图标18、前缀图标20，移除滑块圆点阴影。
- Riverpod、MVVM、GoRouter、计算算法和复制行为保持现有实现。

## 对比方式与已知差异
实际截图去除顶部104px系统栏和底部48px导航栏，统一到390px宽；原图等比例缩放至390px宽，按相同顶部坐标进行50%叠加和绝对像素差，不拉伸页面以掩盖布局差异。

保留之前用户确认的修正：不重复网络号/广播号，不复制稿件的错误演示值、不制造缺失结果的空白。/24结果为254台可用、256个IP。
中文字体由系统回退，Material图标与网页Material Symbols形状存在细微差别；原图缺少可见返回箭头，但应用保留可用返回按钮。深色使用既有配色模板，原图只提供浅色。

## 实际截图验证
- 第一轮：`doc/ui/net-calc/Nov-6-v1.png`。
- 根据第一轮截图修正控件尺寸后重新构建、安装、运行，最终截图：`doc/ui/net-calc/Nov-6-final.png`。
- 归一化原图：`Nov-6-reference-normalized.png`；最终归一化截图：`Nov-6-final-normalized.png`。
- 两轮对比分别保存为 `Nov-6-v1-overlay.png` / `Nov-6-v1-diff.png` 和 `Nov-6-final-overlay.png` / `Nov-6-final-diff.png`。
- 最终叠加仍可见文字基线、卡片纵向位置偏差，未达到逐像素一致。保留平台字体缩放和触摸目标导致部分尺寸与CSS盒模型不同。
- Android debug APK构建成功；全项目静态分析及最终修改文件分析无问题。
- 首次并发全量测试遭遇内存不足，改为 concurrency=1 串行重跑。
- 最终串行全量测试：141项全部通过（flutter test --no-pub --concurrency=1）。
