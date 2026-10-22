# Oct-18 更新说明

## 需求

依据 `doc/requirements/target-Oct-18.md` 调整神机资产卡片的层级信息、字段位置、时间格式和返回按钮，并统一主页、Wiki、神机的顶栏字体规格。

## 改动

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `lib/features/iadb/models/iadb_models.dart` | 修改 | 部门、位置父级名称组合及分钟级时间格式化 |
| `lib/features/iadb/view/iadb_asset_card.dart` | 修改 | 类型/厂商/描述位置调整、使用格式化时间 |
| `lib/core/theme/page_header_typography.dart` | 新增 | 共享 18px w700 标题、12px w400 副标题 |
| `lib/features/home/view/home_page.dart` | 修改 | 主页标题/副标题应用共享规格，保留品牌动画 |
| `lib/features/article/view/widgets/wiki_theme.dart` | 修改 | Wiki 标题/副标题应用共享规格 |
| `lib/features/iadb/view/iadb_page.dart` | 修改 | 神机标题/副标题应用共享规格，返回图标改为尖括号 |
| `test/iadb_oct18_test.dart` | 新增 | 层级、时间边界、Wiki 字体及返回行为 |
| `test/iadb_layout_test.dart`、`test/iadb_test.dart`、`test/home_smoke_test.dart` | 修改 | 卡片字段位置、层级、顶栏字号字重回归断言 |

## 显示规则

- 部门：`department_parent.name · department.name`。
- 位置：`location_parent1.name · location_parent2.name · location.name`，严格保留需求指定顺序。
- 父级按搜索上下文中的同名字段读取，兼容名称字符串及含 name 的对象；空层级跳过，同名的不同层级不去重。接口未提供父级时继续展示已返回的层级，不猜测名称。
- 卡片左上标签改为 `asset.asset_type`；右上改为 `asset.description`；原描述区域改为 `asset.vendor`。资产编号仍可在详情中查看。
- 创建时间显示为 `YYYY-MM-DD HH:MM`；兼容空格或 T 分隔的时间、秒/小数和时区后缀，保留接口时间的钟面值。无效日期/时间统一显示「—」。
- 神机返回图标采用与 Wiki 一致的 `arrow_back_ios_new_rounded`，继续返回上一页。
- 三处标题统一为 18px、w700，副标题为 12px、w400；颜色与文字保持原有设置。主页的 GuoXiang BusyBox 品牌入场动画不变。

## 验证

- 静态分析：0 问题。
- 全项目自动化测试：101 项全部通过。新增 6 项测试，覆盖父级层级与空值、合法/无效日期、Wiki 顶栏字体、神机返回图标和返回行为；既有测试补充卡片字段、层级及三处字号字重断言。
- 测试使用合成数据和既有 MockClient，不依赖真实后端。本轮未验证生产接口是否已经返回新增父级字段。
- 本轮未构建 APK，未进行 Android 真机验证。

## 依赖与后期扩展

本轮没有新增依赖。新增顶栏请复用 `PageHeaderTypography`；后续如需统一时区，先明确后端时间约定再修改模型格式化逻辑。父级字段需由搜索 API 提供，本轮不增加额外的层级查询接口。

> Oct-19 更正：实际搜索没有直接返回上述父级名称字段，Oct-18 实现未完成真实数据补全。现已通过 parent_id 和单条查询修复，详见 update-Oct-19.md。
