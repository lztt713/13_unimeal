# 食谱数据补全（2026-09-08）

本次保留表结构、现有用户数据、食谱份数和报价，只补充缺失记录。

- 两张缺失图片：Tomato Rice Bowl、Egg on Toast。
- 六道空食谱的食材明细：按 database/sample_data.sql 已有 frontend_recipe_ingredient_seed 补入18条记录。
- 缺失步骤：恢复原示例中的18条步骤，并为 Egg on Toast 补入3条步骤；Tomato Rice Bowl 原有步骤保留。
- 当前8道菜均有3条食材明细，合计24条；步骤合计23条。
- 脚本：database/migrations/20260908_complete_recipe_details.sql。仅在缺失时插入/更新，已验证重复执行不改变数据。
- 执行前完整数据库备份位于本机 .local/before_recipe_completion_20260908_111121.sql。
- 原有示例数量、份数及报价按项目数据保留，未重新设计配方或进行市场价格校准。

## 图片来源

以下为内置 image_gen 工具生成的菜品示意图，不是实拍图片。资源保存在项目内，并随前端构建复制到 dist，无外部图片服务依赖。

- unimeal_frontend/public/images/recipes/tomato-rice-bowl.png
- unimeal_frontend/public/images/recipes/egg-on-toast.png

生成提示词：

### Tomato Rice Bowl

Use case: photorealistic-natural. Asset type: UniMeal recipe card food image. Create a natural food photograph of Tomato Rice Bowl: a simple white ceramic bowl of cooked rice with sauteed red tomato chunks and small soft onion pieces, modest student meal, neutral light kitchen table, soft daylight, slightly overhead three-quarter angle, appetizing but realistic. Landscape 3:2 composition with entire bowl centered and enough space for a card crop. No egg, no meat, no other dishes, no text or watermark.

### Egg on Toast

Use case: photorealistic-natural. Asset type: UniMeal recipe card food image. Create a natural food photograph of Egg on Toast: soft scrambled eggs made with a little milk on two slices of golden toasted bread on a simple white ceramic plate, modest student breakfast, neutral light kitchen table, soft daylight, slightly overhead three-quarter angle, realistic texture. Landscape 3:2 composition with entire plate centered and enough space for a card crop. No avocado, meat, side dishes, text or watermark.

## 验证

- 前端构建通过。
- 8道食谱列表/详情接口均返回非空食材、数量、单位和准备步骤。
- 两张图片在运行中的网站均返回 HTTP 200 image/png。
