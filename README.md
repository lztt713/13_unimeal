# UniMeal Planner

UniMeal Planner is the group project for 159.333 Programming Project. The repository contains a Vue 3 frontend, a FastAPI backend, and the shared MySQL schema.

## Local setup（一键把数据库 + 后端 + 前端跑起来）

前提：MySQL 服务（`mysql80`）在运行、已装好 Python 和 Node.js（>= 22.18 或 >= 24.12）。

### 第一次：初始化（只跑一次）

```powershell
cd C:\Users\HarryWorld\Desktop\unimeal\13_unimeal
.\setup.ps1
```

`setup.ps1` 会**弹窗问一次 MySQL root 密码**（星号掩码），用来应用数据库脚本
（建库 + 样例数据 + 张展赫的迁移）并装依赖。之后密码写进本地 `.env`（已被 git 忽略）。

### 以后每次：一键启动

```powershell
cd C:\Users\HarryWorld\Desktop\unimeal\13_unimeal
.\run.ps1
```

`run.ps1` 直接从 `.env` 读数据库配置（**不再问密码**），自动打开两个窗口：
后端（8000）+ 前端（5173）。浏览器访问 http://127.0.0.1:5173 即可。
（如果 `.env` 被删了，脚本才会退回弹窗问密码。）

### 跑测试（在 MySQL 上）

```powershell
cd C:\Users\HarryWorld\Desktop\unimeal\13_unimeal
.\test.ps1
```

### 手动方式（不用脚本，3 个终端）

```powershell
# 终端 1：数据库迁移（一次性，需要密码）
mysql -u root -p < database\migrations\20260919_profile_and_notifications.sql

# 终端 2：后端
cd unimeal_backend
python -m uvicorn app.main:app --reload

# 终端 3：前端
cd unimeal_frontend
npm run dev
```

### 登录演示账号

`sample_data.sql` 预置的 `student.alice@...` / `contributor.ben@...` / `admin@...`
是占位 bcrypt 哈希，不是明文 `demo123`，不能直接登录。请用 `POST /api/auth/register`
注册一个新账号（学生/贡献者）来登录。

## Implemented backend flow

- Authentication: register, login, logout, current-user and profile endpoints with
  hashed passwords, signed HttpOnly session cookies, and student/contributor/administrator roles
- Recipe search, detail, create, edit, delete, publication, saved recipes, ratings and comments
  — recipe actions are scoped to the logged-in user (contributors own their recipes)
- Weekly meal-plan entry create/update/delete
- Shopping-list generation with ingredient/unit merging and serving scaling
- Persisted purchased state and purchase timestamps
- Budget summary calculated from purchased shopping-list items
- Dashboard budget, today's dinner, and saved-recipe integration
- Notifications with reminder deduplication, single/all read endpoints
- Recipe image upload, equipment/allergen lookup, and required-equipment persistence
- Profile-aware AI/database recommendations that enforce allergy, budget, dietary,
  cooking-time, cuisine, ingredient, and kitchen-access constraints
- Notification cleanup, student-only favourites, and current-budget synchronisation
- Content reports and administrator overview, management, user/recipe moderation,
  and ingredient-category management

For an existing database, apply both
`database/migrations/20260919_profile_and_notifications.sql` and
`database/migrations/20260923_frontend_equipment_and_allergens.sql`. Fresh installs
can use `setup.ps1`, which applies the schema, sample data, and current migrations.

## Checks（测试 / 构建）

测试跑在 MySQL 上（独立的 `unimeal_test` 库，自动创建、自动清空，不碰开发库）：

```powershell
cd C:\Users\HarryWorld\Desktop\unimeal\13_unimeal
.\test.ps1      # 运行时弹窗问 MySQL 密码，然后跑 python -m unittest discover -s tests -v
```

张展赫的测试文件：`test_auth.py`、`test_recipe_permissions.py`、`test_notifications_and_admin.py`
（跑在 MySQL 上）。`test_planning.py` 是梁子豪的，仍用内存 SQLite，可单独跑或跳过。

```powershell
cd unimeal_frontend
npm run build
```
