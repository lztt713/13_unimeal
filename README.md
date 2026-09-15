# UniMeal 本地初步成品

当前版本在已有 Vue 页面、FastAPI 后端和 MySQL 26 张表上完成联通，用于小组继续修改。

## 打开与启动

本机地址：<http://127.0.0.1:8000>。API 文档：<http://127.0.0.1:8000/docs>。

1. 保持 MySQL80 服务运行。
2. 双击本目录 `Start-UniMeal.cmd`；或在 PowerShell 执行 `powershell -ExecutionPolicy Bypass -File .\Start-UniMeal.ps1`。
3. 打开上面的本机地址。关闭启动窗口或按 Ctrl+C 可停止该次启动的服务。

启动脚本安装项目依赖、检查现有数据库映射、构建前端，然后由同一个 FastAPI 服务提供网页和 API。后续仅启动已有构建可用 `-SkipBuild`；指定其他端口可用 `-Port 8001`。需要 Python 3.12 和满足 `unimeal_frontend/package.json` engines 的 Node.js；本机已准备 `.venv` 和 `node_modules`。

数据库配置位于根目录 `.env`，已在本机填写。配置项为 `DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASSWORD`、`DB_NAME`；库名为 `unimeal_planner`。可选 `DATABASE_URL` 优先于这些独立配置项。`SESSION_SECRET` 保持不变即可让有效登录跨后端重启保留。`.env` 被 Git 忽略，不能随源码提交。

脚本不会建表、重建数据库或导入示例数据。现有库已建好，不要重新运行 schema 或 sample_data 脚本。

## 使用现有页面

- 学生：注册/登录 → 个人资料设定本周预算和偏好 → 浏览、收藏、评分或评论食谱 → 在仪表盘或日历安排餐次 → 购物清单勾选购买 → 查看预算汇总。
- 贡献者：注册时选择 Recipe contributor → Submit recipe 创建草稿 → My Recipes 编辑和发布。每个账户只能修改自己的食谱。
- 管理员：查看真实统计、处理举报、管理账户/食谱状态和食材分类。公开注册不能选择管理员。

原 `sample_data.sql` 的 bcrypt 字段在原文档中标记为占位哈希，不能把原前端的 `demo123` 当作数据库账户密码。现有账户未被改密。学生和贡献者可以直接在注册页创建新账户。如果没有可登录的管理员，可在本目录执行：

```powershell
.\.venv\Scripts\python.exe unimeal_backend/create_local_account.py --email local.admin@unimeal.test --name "Local Administrator" --role administrator
```

按提示输入新账户密码；该命令只新增账户，不覆盖已有账户。浏览器验收所用的临时账户和食谱已清理。

## 已接通的内容

- `unimeal_frontend/src/services/api.js` 调用实际 API，页面不再导入 mock 数据。
- 注册、密码哈希验证、HttpOnly 登录会话、退出、账户角色和所有权检查。
- 个人资料、偏好、过敏信息、本周预算与现有规范化数据表映射。
- 食谱列表/详情、创建/编辑/发布/删除、收藏、评分、评论和食材过敏标签。
- 本周餐次安排、按份数合并食材、持久化购买勾选、按购买记录汇总支出。
- 通知读取/已读、内容举报、管理员统计及管理操作。
- 原助手页基于真实食谱进行本地规则匹配，页面标注 Local recipe matching；不会调用豆包或其他外部模型。
- 真实错误提示、没有晚餐/零预算等空状态和同源网页/API运行。

## 后续开发

保持两个终端运行，在保存前端文件后可即时预览：

```powershell
# 终端一：项目根目录
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir unimeal_backend --reload --host 127.0.0.1 --port 8000

# 终端二
cd unimeal_frontend
npm run dev
```

前端开发地址为 <http://127.0.0.1:5173>，Vite 将 `/api` 代理到 8000。已在 8000 运行初步成品时，先停止旧后端再以 reload 模式启动。

## 验证

```powershell
.\.venv\Scripts\python.exe unimeal_backend/check_database.py
.\.venv\Scripts\python.exe -m pip install -r unimeal_backend/requirements-dev.txt
$env:PYTHONPATH='unimeal_backend'
.\.venv\Scripts\python.exe -m pytest unimeal_backend/tests ai_qa/tests -q
# 明确启用真实 MySQL 集成测试（所有测试事务最终回滚）
$env:UNIMEAL_TEST_MYSQL='1'
.\.venv\Scripts\python.exe -m pytest unimeal_backend/tests ai_qa/tests -q
```

前端检查：在 `unimeal_frontend` 执行 `npx eslint src --no-fix`、`npx oxlint src` 和 `npm run build`。

验证记录见 `docs/qa/LOCAL_INTEGRATION_REPORT.md`。

## 初步版本边界

保留现有页面和 26 张表。通知页显示数据库已有且已到显示时间的通知，没有新增定时推送系统。助手是有限的英文关键词/预算/时间/标签匹配，不是大模型对话。购买时以食材参考价作为本次支出；不接入商超实时价格。会话按本地单进程服务设计，退出会话的撤销记录保存在进程内。本次只交付本地版本，未部署到公网或推送 GitHub；当前目录是没有 `.git` 的源码副本。
