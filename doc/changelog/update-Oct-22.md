# Oct-22 更新说明

## 需求与设计来源

依据 `ai/prompt.md`、`doc/requirements/target-Oct-22.md` 更新。通过 Stitch 读取项目 `2299265049139915786` 的页面 `b52e17b535f74d9fa3e9b51de5e4c96b`，获取截图和 HTML；原始 HTML 保存为 `doc/ui/net-calc/subnetmaskcalculator-Oct-22.html`。

用户已确认按建议修正设计稿异常：采用设计稿的配色、圆角和紧凑布局，仅保留一组网络号/广播号，保留全部真实计算结果并去掉异常空白，不复制演示值。现有实现已符合该方案，本次确认仅更新文档，无需修改代码或重复测试。

## 更新内容

1. 神机登录页提示改为“请使用神机账户登录”，账号流程不变。
2. 网络计算器顶栏复用 PageHeaderTypography：标题18px/w700、副标题12px/w400，副标题为“BusyBox 工具魔盒”；返回按钮与神机一致，系统字体放大时顶栏随文字调整高度。
3. 输入区采用浅灰外框、四个独立输入格、CIDR 胶囊、蓝色前缀文字、灰色滑轨与圆形蓝色滑块、方形加减按钮。
4. 卡片标题增加圆角图标底座，右侧显示实时换算或 IPv4 标准标识；卡片保留12px圆角和轻阴影。
5. 结果区使用紧凑卡片，普通390px屏幕并排显示网络号和广播号；窄屏/放大字体改为纵向，主机数量与总分配空间左右对齐。整块可复制结果支持点击，保持足够触摸区域，并提供复制成功/失败提示。
6. 沿用 BusyBoxPalette 明暗主题、原有 IPv4 计算与校验、/31 和 /32 规则。POE/带宽仍提示“暂未开放”。无新增依赖。

## 文件清单

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| lib/features/iadb/view/iadb_page.dart | 修改 | 登录提示 |
| lib/features/network_calculator/view/network_calculator_page.dart | 修改 | 标题与布局 |
| test/iadb_test.dart | 修改 | 登录提示断言 |
| test/network_calculator_page_test.dart | 修改 | 标题和CIDR断言，保留交互回归 |
| test/network_calculator_layout_test.dart | 新增 | 三种宽度、明暗主题及大字体测试，可选截图 |
| doc/ui/net-calc/subnetmaskcalculator-Oct-22.html | 新增 | Stitch 原始参考 |
| README.md、ai/prompt.md | 修改 | 功能及后续约定 |

## 验证

- 新增6项布局测试覆盖320/390/800px及明暗主题，320px使用2倍字体。
- 已检查 `build/network_calculator_preview/light.png` 和 `dark.png` 的本地组件截图。普通测试无需系统字体；可选截图通过 BUSYBOX_PREVIEW_FONT 和 BUSYBOX_PREVIEW_ICONS 指定字体文件。
- 全量 flutter test --no-pub：118项通过；最终 flutter analyze --no-pub：0问题；git diff --check通过。首次全量测试发现320px两倍测试字体下CIDR横向溢出，已改为上下布局并通过复测。
- 本轮未构建APK，未进行真机测试，未提交或推送。

### 手机对齐补充修复

实际手机反馈“计算结果/IPv4标准”和主机容量区不同行。原因是此前使用固定宽度及字体倍率阈值，将这两处主动切为纵向；主机区两列的字号及独立行高也会造成错位。

- 标题区改为弹性左右布局，两侧共享一行，长文本在各自区域内换行。
- 主机容量区改为两列共享标签行、数值行的 Table，标签顶部对齐，数值按文字基线对齐，避免18px与14px字号产生错位。
- 新增 network_calculator_alignment_test.dart，覆盖320/360/390/412逻辑像素、1/1.3/2倍字体，以及/32和/1的小数值与大数值。屏幕英寸不直接作为布局判断条件。

补充修复验证：全量130项测试通过，最终静态分析0问题，git diff --check通过。尚未在用户的6.74英寸真机上复测，未重新构建APK。
