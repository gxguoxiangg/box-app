# Markdown 知识库后端

为 Flutter 客户端提供知识库数据的**读取**与**推送**接口的 FastAPI 后端。

> 📖 **新手入门请看 [GUIDE.md](GUIDE.md)** —— 一份面向"只有 Python 语法基础、没做过后端"读者的详解文档：请求如何走通全链路、每层代码干什么、如何加字段/加接口/改解析规则。

## 功能

- **Markdown 解析入库**：解析选定的 `.md` 文件（每个文件由多个「一个 H2 + 五个 H3」条目组成，内容含图片链接与代码块），存储到 PostgreSQL。
- **读取 API**：向 Flutter 应用提供文章/条目分页查询与详情接口。
- **推送 API**：接收 Flutter 推送的数据，JWT 鉴权后解析入库（幂等 upsert）。

## 技术栈

Python 3.12 · FastAPI · SQLAlchemy 2.0 (async) · Alembic · PostgreSQL 16 · Pydantic v2 · JWT · Docker Compose

## 目录结构

```
backend/
├── app/
│   ├── main.py            # 应用入口（uvicorn app.main:app）
│   ├── core/              # 配置 / 安全 / 依赖
│   ├── db/                # 引擎、会话、ORM 基类、启动初始化
│   ├── models/            # ORM 模型（articles/items/images/code_blocks/...）
│   ├── schemas/           # Pydantic 请求/响应契约
│   ├── services/          # 业务逻辑（解析器、入库服务）
│   └── api/v1/            # 路由（auth/articles/items/push）
├── scripts/               # CLI 工具（导入 Markdown、创建用户）
├── alembic/               # 数据库迁移
├── tests/                 # pytest 测试
└── docker-compose.yml     # PostgreSQL + API 一键启动
```

> Markdown 源文件放在 **上级目录的 `doc/`**（即 `.../Python/doc/`），
> 已通过 Docker 卷挂载到容器内 `/doc`，供容器内导入使用。

### 方式一：Docker（推荐）

```bash
cp .env.example .env
docker compose up -d --build
```

- API: http://localhost:8000，Swagger: http://localhost:8000/docs
- 首次启动会自动执行 `alembic upgrade head` 并创建管理员 `admin / admin123`。

#### 在 Docker 里导入 Markdown 资料

`api` 容器已把宿主机 `doc/` 目录（与 `backend/` 同级）**只读挂载**到容器内 `/doc`。
把你想要导入的 `.md` 文件放进 `doc/`，然后在 `backend/` 目录下执行：

```bash
# 1. 把文件放进宿主 doc/ 目录，例如 doc/acticle1.md
# 2. 在容器内导入（容器内文件路径是 /doc/<文件名>）
docker compose exec api python scripts/ingest_markdown.py /doc/acticle1.md --external-key kb:acticle1
```

看到类似输出即导入成功：

```
读取文件：acticle1.md ...
解析完成：标题='桌面问题'，条目数=69，图片=42，代码块=24
入库完成：created（article_id=1，条目 69 个）
```

验证：

```bash
curl http://localhost:8000/api/v1/articles
```

> 说明：
> - 挂载路径：`../doc:/doc:ro`（相对 `docker-compose.yml` 所在目录 `backend/`，即宿主 `.../Python/doc`）。
> - 导入是幂等的：同一文件重复导入会整篇替换（见 `--external-key` 幂等键机制）。
> - 每次换文件内容后重新导入即可更新，无需重建容器。

### 方式二：本地开发

1. 准备 PostgreSQL（任意方式，如 Docker 只启动 db：`docker compose up -d db`）。
2. 配置 `.env`（参考 `.env.example` 的 `DATABASE_URL`）。
3. 安装依赖并迁移：

```bash
python -m venv .venv
source .venv/Scripts/activate        # Windows Git Bash
pip install -r requirements.txt
pip install -r requirements-dev.txt
alembic upgrade head
```

4. 创建用户并导入语料：

```bash
python scripts/create_user.py --username admin --password admin123
python scripts/ingest_markdown.py "../doc/acticle1.md" --external-key kb:acticle1
```

5. 启动服务：

```bash
uvicorn app.main:app --reload
```

## API 概览

| 方法 | 路径 | 说明 | 鉴权 |
|---|---|---|---|
| POST | `/api/v1/auth/login` | 用户名密码换取 JWT | 无 |
| GET | `/api/v1/auth/me` | 当前用户 | Bearer |
| GET | `/api/v1/articles` | 文章分页列表（`tag`/`q` 过滤） | 无 |
| GET | `/api/v1/articles/{id}` | 文章详情（嵌套全部条目） | 无 |
| GET | `/api/v1/items` | 条目分页列表（`article_id`/`q` 过滤） | 无 |
| GET | `/api/v1/items/{id}` | 条目详情（图片/代码块/关键词） | 无 |
| POST | `/api/v1/push/article` | 整篇推送（幂等替换） | Bearer |
| POST | `/api/v1/push/item` | 单条目推送（幂等追加/更新） | Bearer |





这是 api：http://159.75.86.98:8000/api/v1/items/47 的返回示例。

```json
{
  "id": 47,
  "article_id": 1,
  "position": 46,
  "question": "Q - Microsoft Store 安装的国外应用网络异常",
  "description": "Microsoft Store 安装的 Whatsapp 不显示登录二维码，无法使用，网络代理正常。",
  "causes": "在Windows10有AppContainer机制，而UWP是在AppContainer中隔离运行。正是因为这个特性，UWP应用不可以访问本地回环地址（127.0.0.1）。这意味着，一些利用本地回环进行代理的工具，如 V2ray 无法对UWP应用代理网络访问。",
  "solutions": "**1.如果代理内置于路由器中，如OpenWrt，则应该可以访问。**\n**2.现代的一些开源代理软件，自带有解除 UWP 应用限制的功能。**\n**3.如果需要手动解除，步骤如下：**\n**方法一.使用CheckNetIsolation工具：**\n首先需要获取UWP应用的SID或者程序包名称。SID需要通过注册表来查找，比较麻烦。程序包名称可以在用户文件夹中查找到，方法如下： 按下win+R，呼出“运行”， 输入以下地址：\n```powershell\nC:\\Users\\%username%\\AppData\\Local\\Packages\n```\n打开资源管理器后，其中的文件夹名称就是对应UWP的程序包名称。例如：OneNote是`Microsoft.Office.OneNote_8wekyb3d8bbwe`\n然后在”运行“中输入`cmd`，打开命令提示符，输入以下命令，即可解除UWP的本地回环的限制：\n```powershell\nCheckNetIsolation LoopbackExempt -a -n=\"[程序包名称]\"\n```\n该命令详细的介绍如下所示：\n```powershell\nCheckNetIsolation LoopbackExempt [operation] [-n=] [-p=]\n      操作列表:\n          -a  -  向环回免除列表中添加 AppContainer 或程序包系列。\n          -d  -  从环回免除列表中删除 AppContainer 或程序包系列。\n          -c  -  清除环回免除的 AppContainer 和程序包系列的列表。\n          -s  -  显示环回免除的 AppContainer 和程序包系列的列表。\n\n      参数列表:\n          -n= - AppContainer 名称或程序包系列名称。\n          -p= - AppContainer 或程序包系列安全标识符(SID)。\n          -?  - 显示 LoopbackExempt 模块的此帮助消息。\n```\n**方法二.借助Fiddler工具：**\nFiddler是一个抓包工具，其中有一个部件可以达到上述方法同样的效果：\n安装并打开该工具，点击左上角\n![img](https://img2020.cnblogs.com/blog/1900676/202102/1900676-20210202171413501-714193518.png)\n\n![img](https://img2020.cnblogs.com/blog/1900676/202102/1900676-20210202171441226-1188897475.png)\n勾选需要解除限制的UWP应用，并点击”SaveChanges“即可。",
  "review": "参考链接：\n- [UWP应用的网络流量不能通过小飞机等代理工具的解决办法 ](https://www.cnblogs.com/optimo/p/14363226.html)\n- [为Win10-UWP应用使用设置代理](https://zhuanlan.zhihu.com/p/128965700)\n- [解决电脑版WhatsApp不显示二维码的问题,修复WhatsApp无法扫描二维码问题](https://zhuanlan.zhihu.com/p/698977371)",
  "keywords": "- UWP\n- 代理",
  "description_html": "\u003Cp\u003EMicrosoft Store 安装的 Whatsapp 不显示登录二维码，无法使用，网络代理正常。\u003C/p\u003E\n",
  "causes_html": "\u003Cp\u003E在Windows10有AppContainer机制，而UWP是在AppContainer中隔离运行。正是因为这个特性，UWP应用不可以访问本地回环地址（127.0.0.1）。这意味着，一些利用本地回环进行代理的工具，如 V2ray 无法对UWP应用代理网络访问。\u003C/p\u003E\n",
  "solutions_html": "\u003Cp\u003E\u003Cstrong\u003E1.如果代理内置于路由器中，如OpenWrt，则应该可以访问。\u003C/strong\u003E\n\u003Cstrong\u003E2.现代的一些开源代理软件，自带有解除 UWP 应用限制的功能。\u003C/strong\u003E\n\u003Cstrong\u003E3.如果需要手动解除，步骤如下：\u003C/strong\u003E\n\u003Cstrong\u003E方法一.使用CheckNetIsolation工具：\u003C/strong\u003E\n首先需要获取UWP应用的SID或者程序包名称。SID需要通过注册表来查找，比较麻烦。程序包名称可以在用户文件夹中查找到，方法如下： 按下win+R，呼出“运行”， 输入以下地址：\u003C/p\u003E\n\u003Cpre\u003E\u003Ccode class=\"language-powershell\"\u003EC:\\Users\\%username%\\AppData\\Local\\Packages\n\u003C/code\u003E\u003C/pre\u003E\n\u003Cp\u003E打开资源管理器后，其中的文件夹名称就是对应UWP的程序包名称。例如：OneNote是\u003Ccode\u003EMicrosoft.Office.OneNote_8wekyb3d8bbwe\u003C/code\u003E\n然后在”运行“中输入\u003Ccode\u003Ecmd\u003C/code\u003E，打开命令提示符，输入以下命令，即可解除UWP的本地回环的限制：\u003C/p\u003E\n\u003Cpre\u003E\u003Ccode class=\"language-powershell\"\u003ECheckNetIsolation LoopbackExempt -a -n=&quot;[程序包名称]&quot;\n\u003C/code\u003E\u003C/pre\u003E\n\u003Cp\u003E该命令详细的介绍如下所示：\u003C/p\u003E\n\u003Cpre\u003E\u003Ccode class=\"language-powershell\"\u003ECheckNetIsolation LoopbackExempt [operation] [-n=] [-p=]\n      操作列表:\n          -a  -  向环回免除列表中添加 AppContainer 或程序包系列。\n          -d  -  从环回免除列表中删除 AppContainer 或程序包系列。\n          -c  -  清除环回免除的 AppContainer 和程序包系列的列表。\n          -s  -  显示环回免除的 AppContainer 和程序包系列的列表。\n\n      参数列表:\n          -n= - AppContainer 名称或程序包系列名称。\n          -p= - AppContainer 或程序包系列安全标识符(SID)。\n          -?  - 显示 LoopbackExempt 模块的此帮助消息。\n\u003C/code\u003E\u003C/pre\u003E\n\u003Cp\u003E\u003Cstrong\u003E方法二.借助Fiddler工具：\u003C/strong\u003E\nFiddler是一个抓包工具，其中有一个部件可以达到上述方法同样的效果：\n安装并打开该工具，点击左上角\n\u003Cimg src=\"https://img2020.cnblogs.com/blog/1900676/202102/1900676-20210202171413501-714193518.png\" alt=\"img\" /\u003E\u003C/p\u003E\n\u003Cp\u003E\u003Cimg src=\"https://img2020.cnblogs.com/blog/1900676/202102/1900676-20210202171441226-1188897475.png\" alt=\"img\" /\u003E\n勾选需要解除限制的UWP应用，并点击”SaveChanges“即可。\u003C/p\u003E\n",
  "review_html": "\u003Cp\u003E参考链接：\u003C/p\u003E\n\u003Cul\u003E\n\u003Cli\u003E\u003Ca href=\"https://www.cnblogs.com/optimo/p/14363226.html\"\u003EUWP应用的网络流量不能通过小飞机等代理工具的解决办法 \u003C/a\u003E\u003C/li\u003E\n\u003Cli\u003E\u003Ca href=\"https://zhuanlan.zhihu.com/p/128965700\"\u003E为Win10-UWP应用使用设置代理\u003C/a\u003E\u003C/li\u003E\n\u003Cli\u003E\u003Ca href=\"https://zhuanlan.zhihu.com/p/698977371\"\u003E解决电脑版WhatsApp不显示二维码的问题,修复WhatsApp无法扫描二维码问题\u003C/a\u003E\u003C/li\u003E\n\u003C/ul\u003E\n",
  "keywords_html": "\u003Cul\u003E\n\u003Cli\u003EUWP\u003C/li\u003E\n\u003Cli\u003E代理\u003C/li\u003E\n\u003C/ul\u003E\n",
  "images": [
    {
      "id": 28,
      "section": "solutions",
      "format": "markdown",
      "alt_text": "img",
      "url": "https://img2020.cnblogs.com/blog/1900676/202102/1900676-20210202171413501-714193518.png",
      "size": null,
      "position": 0
    },
    {
      "id": 29,
      "section": "solutions",
      "format": "markdown",
      "alt_text": "img",
      "url": "https://img2020.cnblogs.com/blog/1900676/202102/1900676-20210202171441226-1188897475.png",
      "size": null,
      "position": 1
    }
  ],
  "code_blocks": [
    {
      "id": 17,
      "section": "solutions",
      "language": "powershell",
      "code": "C:\\Users\\%username%\\AppData\\Local\\Packages\n",
      "position": 0
    },
    {
      "id": 18,
      "section": "solutions",
      "language": "powershell",
      "code": "CheckNetIsolation LoopbackExempt -a -n=\"[程序包名称]\"\n",
      "position": 1
    },
    {
      "id": 19,
      "section": "solutions",
      "language": "powershell",
      "code": "CheckNetIsolation LoopbackExempt [operation] [-n=] [-p=]\n      操作列表:\n          -a  -  向环回免除列表中添加 AppContainer 或程序包系列。\n          -d  -  从环回免除列表中删除 AppContainer 或程序包系列。\n          -c  -  清除环回免除的 AppContainer 和程序包系列的列表。\n          -s  -  显示环回免除的 AppContainer 和程序包系列的列表。\n\n      参数列表:\n          -n= - AppContainer 名称或程序包系列名称。\n          -p= - AppContainer 或程序包系列安全标识符(SID)。\n          -?  - 显示 LoopbackExempt 模块的此帮助消息。\n",
      "position": 2
    }
  ],
  "keywords_list": [
    {
      "id": 88,
      "keyword": "UWP",
      "position": 0
    },
    {
      "id": 89,
      "keyword": "代理",
      "position": 1
    }
  ]
}
```





这是 api http://159.75.86.98:8000/api/v1/items 的返回示例。

```json
{
  "total": 69,
  "page": 1,
  "page_size": 20,
  "items": [
    {
      "id": 1,
      "article_id": 1,
      "position": 0,
      "question": "Q - Excel 文档全屏显示",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 2,
      "article_id": 1,
      "position": 1,
      "question": "Q - Microsoft Office 自定义安装",
      "has_images": false,
      "has_code": true
    },
    {
      "id": 3,
      "article_id": 1,
      "position": 2,
      "question": "Q - 系统缺少 Microsoft Print to PDF 打印机",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 4,
      "article_id": 1,
      "position": 3,
      "question": "Q - 无法上网系列问题",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 5,
      "article_id": 1,
      "position": 4,
      "question": "Q - Outlook 2010 发邮件时出现：无法完成该操作，一个或多个参数值无效",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 6,
      "article_id": 1,
      "position": 5,
      "question": "Q - Outlook 本地数据文件相关问题",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 7,
      "article_id": 1,
      "position": 6,
      "question": "Q - Windows SMB 共享文件夹设置",
      "has_images": true,
      "has_code": true
    },
    {
      "id": 8,
      "article_id": 1,
      "position": 7,
      "question": "Q - Windows 打印队列相关问题",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 9,
      "article_id": 1,
      "position": 8,
      "question": "Q - Macbook 重装系统",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 10,
      "article_id": 1,
      "position": 9,
      "question": "Q - WPS 制作的表格中的图片，在微软的 Excel 上无法正常显示。",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 11,
      "article_id": 1,
      "position": 10,
      "question": "Q - 品牌电脑重装系统后无法正常进入系统",
      "has_images": true,
      "has_code": false
    },
    {
      "id": 12,
      "article_id": 1,
      "position": 11,
      "question": "Q - 硬盘接口问题",
      "has_images": true,
      "has_code": false
    },
    {
      "id": 13,
      "article_id": 1,
      "position": 12,
      "question": "Q - 业务网站缺少图标，显示不全和功能缺失",
      "has_images": true,
      "has_code": true
    },
    {
      "id": 14,
      "article_id": 1,
      "position": 13,
      "question": "Q - Microsoft Exchange 邮箱撤回邮件",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 15,
      "article_id": 1,
      "position": 14,
      "question": "Q - WPS 软件版本号解读",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 16,
      "article_id": 1,
      "position": 15,
      "question": "Q - 老式电脑硬盘占用过高",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 17,
      "article_id": 1,
      "position": 16,
      "question": "Q - LTSC2021 系统 CPU 占用过高",
      "has_images": false,
      "has_code": true
    },
    {
      "id": 18,
      "article_id": 1,
      "position": 17,
      "question": "Q - Word 调整某段文字的段落格式时，整个文档格式都跟着变",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 19,
      "article_id": 1,
      "position": 18,
      "question": "Q - Office 文件图标显示异常",
      "has_images": true,
      "has_code": true
    },
    {
      "id": 20,
      "article_id": 1,
      "position": 19,
      "question": "Q - Windows 10 配置护眼颜色",
      "has_images": false,
      "has_code": true
    }
  ]
}
```



这是搜索APIhttp://159.75.86.98:8000/api/v1/items?q=Windows的示例

```json
{
  "total": 8,
  "page": 1,
  "page_size": 20,
  "items": [
    {
      "id": 7,
      "article_id": 1,
      "position": 6,
      "question": "Q - Windows SMB 共享文件夹设置",
      "has_images": true,
      "has_code": true
    },
    {
      "id": 8,
      "article_id": 1,
      "position": 7,
      "question": "Q - Windows 打印队列相关问题",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 20,
      "article_id": 1,
      "position": 19,
      "question": "Q - Windows 10 配置护眼颜色",
      "has_images": false,
      "has_code": true
    },
    {
      "id": 27,
      "article_id": 1,
      "position": 26,
      "question": "Q - Windows 登录后进入桌面显示黑屏",
      "has_images": true,
      "has_code": true
    },
    {
      "id": 31,
      "article_id": 1,
      "position": 30,
      "question": "Q - 禁用 Windows 自动更新",
      "has_images": false,
      "has_code": false
    },
    {
      "id": 60,
      "article_id": 1,
      "position": 59,
      "question": "Q - 在 Windows 家庭版中设置超级管理员账号",
      "has_images": false,
      "has_code": true
    },
    {
      "id": 68,
      "article_id": 1,
      "position": 67,
      "question": "Q - 无U盘的情况下重置Windows本地账户密码",
      "has_images": true,
      "has_code": false
    },
    {
      "id": 69,
      "article_id": 1,
      "position": 68,
      "question": "Q - Windows 目录中无法按文件名称顺序进行排序",
      "has_images": true,
      "has_code": false
    }
  ]
}
```







### 推送示例（Flutter 端）

```bash
# 1. 登录获取 token
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -d "username=admin&password=admin123" | python -c "import sys,json;print(json.load(sys.stdin)['access_token'])")

# 2. 整篇推送
curl -X POST http://localhost:8000/api/v1/push/article \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"示例","external_key":"kb:demo","items":[{"question":"Q - 示例问题","solutions":"方案"}]}'
```

## 测试

```bash
# 解析器单测（不依赖数据库）
pytest tests/test_markdown_parser.py -q

# 全部测试（含 API；需要可用的 PostgreSQL，可用 TEST_DATABASE_URL 指定）
pytest -q
```

## 关键设计

- **单一数据契约**：CLI 导入与 Flutter 推送都产出 `PushArticleIn`，走同一套 `upsert_article()`，保证两条路径存储行为一致。
- **幂等键**：文章按 `external_key`/`source_file` 幂等；条目按 `(article_id, external_key)` 幂等。
- **解析器健壮性**：兼容三种图片格式（`![alt](url)`、`![[file|size]]`、内联 `<img>`）、缩进/尾随空格 fence、`null` 小节、`==高亮==`，渲染 HTML 供客户端直接展示。
- **子对象规范化**：图片/代码块/关键词独立成表，便于按类型查询与未来扩展。
- **审计**：每次推送写入 `push_events`，保留原文可追溯。





