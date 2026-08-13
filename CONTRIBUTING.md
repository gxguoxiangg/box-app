# 贡献指南

本仓库的协作规范参考大厂团队实践（Conventional Commits / Trunk-Based Development），
包括提交信息格式、分支策略、提交前检查等，便于后期持续迭代与多人协作。

---

## 一、提交信息规范（Conventional Commits）

提交信息统一采用 **Conventional Commits** 格式（Angular 项目同款，被主流团队广泛采用）：

```
<type>(<scope>): <subject>
```

### 1. type（必填）

| type | 含义 |
| --- | --- |
| `feat` | 新功能 |
| `fix` | 修复 bug |
| `docs` | 仅文档变更 |
| `style` | 不影响逻辑的格式调整（空格、格式化等） |
| `refactor` | 重构（既不新增功能也不修复 bug） |
| `perf` | 性能优化 |
| `test` | 新增或修正测试 |
| `chore` | 构建配置、.gitignore、依赖等辅助变更 |

### 2. scope（可选）

标识影响范围，如 `home`、`article`、`network`、`theme`。示例：

```
feat(network): 新增网络信息模块
fix(home): 修复侧边栏无法打开的问题
```

### 3. subject 要求

- 用**动词开头**、祈使句（如 "新增"、"修复"，而非 "新增了"/"修复了"）；
- 简洁明确，**不超过 50 字符**；
- 避免空泛描述（如 "修复 bug"、"清理代码"）。

### 4. body（可选，重要变更必填）

空一行后写正文，回答三个问题：

1. **改了什么？**
2. **为什么这样改？**
3. **如何验证？**（测试命令 / 结果）

示例：

```
feat(network): 新增网络信息模块

- 顶部展示当前连接状态（Wi-Fi / 移动数据 / 无连接）
- 设备网络信息卡片（IP、网关、SSID 等）
- 网站连通延迟网格（每行 3 个）与简化详情页
- 底部操作栏：测试网速（内嵌 WebView）+ 预留按钮

验证：flutter test 全量通过（27 项）。
```

---

## 二、分支策略

本项目采用 **Trunk-Based Development（主干开发）**，适合单人/小团队持续迭代：

| 分支 | 用途 |
| --- | --- |
| `main` | 唯一主干，随时可运行、可部署；**禁止直接推送未验证代码** |
| `feature/<名称>` | 较大功能迭代时使用，完成后经审查合并回 `main` |
| `fix/<名称>` | 缺陷修复分支（可选） |

**工作流程**：
1. 小改动：直接在 `main` 上提交（需通过本地检查，见下）；
2. 大功能：`git checkout -b feature/<名称>` → 开发 → 合并回 `main`；
3. 合并保持线性历史：优先 `git merge --squash` 或 `--ff-only`。

> 如需正式发布周期，可扩展 Git Flow（develop / release / hotfix）。

---

## 三、提交前检查（CI 门槛）

提交/推送前必须通过以下检查，**拒绝半成品**：

```bash
flutter analyze   # 静态分析，0 问题
flutter test      # 全量测试通过
```

本仓库已在 `.git/hooks/pre-push` 安装了**预推送钩子**，推送前自动执行以上检查，
失败则阻止推送。如需临时跳过：

```bash
git push --no-verify
```

> 钩子仅存在于本地 `.git/hooks/`（不入库）；换机器后需重新复制
> `tool/hooks/pre-push` 或自行安装。

---

## 四、Pull Request 规范（多人协作时）

- 单个 PR 尽量小、聚焦一件事（建议变更 ≤ 400 行）；
- 描述说明「为什么改」与「怎么改」，UI 变更附截图；
- 关联相关 Issue / 需求文档；
- 合并前至少 1 人审查 + CI 通过。

---

## 五、版本与变更日志（可选）

本仓库已采用 Conventional Commits，后期可接入自动化版本管理工具
（如 `release-please`）根据提交类型自动生成版本号与 CHANGELOG：

- `feat` → minor 版本
- `fix` → patch 版本
- `BREAKING CHANGE`（body 中标注）→ major 版本
