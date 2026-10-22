# Oct-21 更新说明

## 需求与进度

依据 `ai/prompt.md` 和 `doc/requirements/target-Oct-21.md`，实现网络计算器和神机卡片字段调整。用户已确认权限类别为接口中文键，asset_type 下方大标题直接使用 vendor。

## 神机卡片字段

- asset_type 下方大标题直接显示 asset.vendor，移除 name/description 回退。后续补充：旁边显示 asset.model，厂商 18px、型号 16px；型号为空时隐藏，窄屏或长文本时换行。
- 原 vendor 右侧标签读取 asset["权限类别"]，例如“仅绑定”；不猜测英文替代字段。
- 两个字段缺失、空串或空白时显示“—”；保留右上 description、部门父级回退及网络信息。
- 更新 iadb_asset_card.dart、iadb_test.dart、iadb_layout_test.dart，覆盖指定位置与空值回退。

## 网络计算器

- 参考 `doc/ui/net-calc/subnetmaskcalculator_page.html` 实现横向模式按钮、圆角输入卡片、四段 IP 输入、CIDR 标识、掩码滑块和加减按钮、结果卡片及复制。
- 默认 `192.168.10.1/24`。页面前缀范围 /1–/32，核心计算服务额外支持 /0。输入每段限制十进制三位，数值超过255或为空时显示错误并隐藏旧结果。
- 结果包含掩码、网络起始地址、广播地址、可用主机数量、总地址数和可用范围。/31 按点对点两主机处理，/32 按单主机处理，广播显示“—”并给出说明。
- 复制通过平台剪贴板；成功和失败都有反馈。POE/带宽仅显示“暂未开放”，不切换为虚假页面。
- 复用 BusyBoxPalette，支持明暗主题；窄屏/放大字体时网络号与广播号纵向排列，正文可滚动。
- 接入主页目录、常用工具及功能搜索；保留 network_calculator 标识，不影响既有自定义设置。

## 代码结构

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| lib/features/network_calculator/models/subnet_result.dart | 新增 | 结果快照 |
| lib/features/network_calculator/data/subnet_calculator.dart | 新增 | 跨平台本地计算与校验 |
| lib/features/network_calculator/viewmodel/subnet_viewmodel.dart | 新增 | Riverpod 自动释放输入/结果状态 |
| lib/features/network_calculator/view/network_calculator_page.dart | 新增 | 页面与交互 |
| lib/features/home/data/home_catalog.dart | 修改 | 启用已有入口 |
| lib/features/home/data/tool_registry.dart | 修改 | 搜索目录与路由常量 |
| lib/app/router/app_router.dart | 修改 | 注册页面 |
| test/subnet_calculator_test.dart | 新增 | 数值、输入、生命周期回归 |
| test/network_calculator_page_test.dart | 新增 | 目录、窄屏、明暗主题、输入和复制交互 |

无新增依赖，计算不调用接口。所有测试离线运行，剪贴板使用 Mock。尚未构建 APK 或进行真机验证。

## 验证

- 网络计算器接入后执行全量 `flutter test --no-pub`：111 项全部通过（包含新增 7 项计算器测试）。
- 用户确认神机字段后修改卡片，执行 4 个神机测试文件：20 项全部通过（新增 1 项空值回归）；本次定向复测覆盖最终卡片修改。
- 最终 `flutter analyze --no-pub`：0 问题。
- `git diff --check`：通过。
- 本次共新增 8 项测试。未新增依赖，未构建 APK，未提交或推送。

### 型号显示补充验证

厂商与型号布局、空型号隐藏及神机页面回归共 11 项测试通过，覆盖 320px 窄屏、1.3 倍字体和明暗主题。
