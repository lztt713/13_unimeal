-- Database support for frontend v6. Run after master_schema.sql and seed data.
-- Existing installations: run this migration without re-importing sample_data.sql.
-- MySQL DDL commits implicitly. Take a backup before upgrading an existing database.
-- Re-running adds missing reference rows/links, without replacing user records.
USE unimeal_planner;

-- Also reconcile the two existing 20260919 fields with fresh installations.
DROP PROCEDURE IF EXISTS apply_frontend_v6_columns;
DELIMITER //
CREATE PROCEDURE apply_frontend_v6_columns()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'weekly_budget'
  ) THEN
    ALTER TABLE users ADD COLUMN weekly_budget DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER favourite_cuisines_note;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'notifications' AND column_name = 'dedupe_key'
  ) THEN
    ALTER TABLE notifications ADD COLUMN dedupe_key VARCHAR(255) NULL AFTER message;
  END IF;
END //
DELIMITER ;
CALL apply_frontend_v6_columns();
DROP PROCEDURE apply_frontend_v6_columns;

CREATE TABLE IF NOT EXISTS equipment (
  equipment_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  equipment_name VARCHAR(80) NOT NULL,
  description VARCHAR(255) NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT ck_equipment_name CHECK (CHAR_LENGTH(TRIM(equipment_name)) > 0),
  UNIQUE KEY uq_equipment_name (equipment_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipe_equipment (
  recipe_id BIGINT UNSIGNED NOT NULL,
  equipment_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (recipe_id, equipment_id),
  CONSTRAINT fk_recipe_equipment_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
  CONSTRAINT fk_recipe_equipment_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE RESTRICT,
  KEY idx_recipe_equipment_equipment (equipment_id)
) ENGINE=InnoDB;

START TRANSACTION;

-- Controlled equipment options for GET /equipment. Names, not numeric IDs,
-- identify reference records so existing auto-increment values can differ.
INSERT INTO equipment (equipment_name, description)
SELECT seed.equipment_name, seed.description
FROM (
  SELECT 'Hob' AS equipment_name, 'A stovetop or portable cooking hob.' AS description
  UNION ALL SELECT 'Saucepan', 'A pan for boiling or simmering food.'
  UNION ALL SELECT 'Frying pan', 'A pan for frying or sauteing food.'
  UNION ALL SELECT 'Toaster', 'An appliance for toasting bread.'
  UNION ALL SELECT 'Oven', 'An oven for baking or roasting.'
  UNION ALL SELECT 'Microwave', 'A microwave oven for heating food.'
  UNION ALL SELECT 'Blender', 'A blender suitable for the recipe ingredients.'
  UNION ALL SELECT 'Rolling pin', 'A rolling pin for dough or fresh pasta.'
) seed
WHERE NOT EXISTS (SELECT 1 FROM equipment e WHERE e.equipment_name = seed.equipment_name);

-- Keep the existing Dairy/Egg/Peanut/Gluten labels, including user references.
-- This is an application pick-list, not a complete regulatory allergen standard.
INSERT INTO allergies (allergy_name)
SELECT seed.allergy_name
FROM (
  SELECT 'Dairy' AS allergy_name UNION ALL SELECT 'Egg'
  UNION ALL SELECT 'Peanut' UNION ALL SELECT 'Gluten'
  UNION ALL SELECT 'Wheat' UNION ALL SELECT 'Soy'
  UNION ALL SELECT 'Sesame' UNION ALL SELECT 'Tree Nuts'
  UNION ALL SELECT 'Fish' UNION ALL SELECT 'Shellfish'
) seed
WHERE NOT EXISTS (SELECT 1 FROM allergies a WHERE a.allergy_name = seed.allergy_name);

-- Positive mappings for the supplied conventional seed ingredients.
-- Bread/Pasta/Wrap represent wheat-based products in this fixture, not gluten-free variants.
-- No substring matching: Coconut Milk must not be treated as dairy Milk.
-- Compound foods such as Hummus and Vegetable Stock need product-label review;
-- an absent mapping is NOT evidence that an ingredient is allergen-free.
INSERT INTO ingredient_allergens (ingredient_id, allergy_id)
SELECT i.ingredient_id, a.allergy_id
FROM (
  SELECT 'Milk' AS ingredient_name, 'Dairy' AS allergy_name
  UNION ALL SELECT 'Cream', 'Dairy'
  UNION ALL SELECT 'Egg', 'Egg'
  UNION ALL SELECT 'Bread', 'Gluten'
  UNION ALL SELECT 'Bread', 'Wheat'
  UNION ALL SELECT 'Pasta', 'Gluten'
  UNION ALL SELECT 'Pasta', 'Wheat'
  UNION ALL SELECT 'Wrap', 'Gluten'
  UNION ALL SELECT 'Wrap', 'Wheat'
  UNION ALL SELECT 'Wheat Flour', 'Gluten'
  UNION ALL SELECT 'Wheat Flour', 'Wheat'
) seed
JOIN ingredients i ON i.ingredient_name = seed.ingredient_name
JOIN allergies a ON a.allergy_name = seed.allergy_name
WHERE NOT EXISTS (
  SELECT 1 FROM ingredient_allergens ia
  WHERE ia.ingredient_id = i.ingredient_id AND ia.allergy_id = a.allergy_id
);

-- Backfill only supplied seed recipes whose equipment list is still empty.
-- Author + title avoids attaching equipment to another contributor's same-named recipe.
-- Existing equipment selections are preserved. No-cook wraps need no listed appliance.
INSERT INTO recipe_equipment (recipe_id, equipment_id)
SELECT r.recipe_id, e.equipment_id
FROM (
  SELECT 'contributor.ben@unimeal.test' AS author_email, 'Tomato Rice Bowl' AS title, 'Hob' AS equipment_name
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Tomato Rice Bowl', 'Saucepan'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Tomato Rice Bowl', 'Frying pan'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Egg on Toast', 'Hob'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Egg on Toast', 'Frying pan'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Egg on Toast', 'Toaster'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Chickpea Coconut Curry', 'Hob'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Chickpea Coconut Curry', 'Saucepan'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Creamy Tomato Pasta', 'Hob'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Creamy Tomato Pasta', 'Saucepan'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Garlic Mushroom Toast', 'Hob'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Garlic Mushroom Toast', 'Frying pan'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Garlic Mushroom Toast', 'Toaster'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Spiced Lentil Soup', 'Hob'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Spiced Lentil Soup', 'Saucepan'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Spiced Lentil Soup', 'Blender'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Teriyaki Chicken Rice Bowl', 'Hob'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Teriyaki Chicken Rice Bowl', 'Saucepan'
  UNION ALL SELECT 'contributor.ben@unimeal.test', 'Teriyaki Chicken Rice Bowl', 'Frying pan'
  UNION ALL SELECT 'yuki@qq.com', 'Tomato and Hummus Toast', 'Toaster'
  UNION ALL SELECT 'yuki@qq.com', 'Chicken and Broccoli Pasta', 'Hob'
  UNION ALL SELECT 'yuki@qq.com', 'Chicken and Broccoli Pasta', 'Saucepan'
  UNION ALL SELECT 'yuki@qq.com', 'Chicken and Broccoli Pasta', 'Frying pan'
  UNION ALL SELECT 'yuki@qq.com', 'Mushroom Egg Fried Rice', 'Hob'
  UNION ALL SELECT 'yuki@qq.com', 'Mushroom Egg Fried Rice', 'Saucepan'
  UNION ALL SELECT 'yuki@qq.com', 'Mushroom Egg Fried Rice', 'Frying pan'
  UNION ALL SELECT 'yuki@qq.com', 'Creamy Mushroom Risotto', 'Hob'
  UNION ALL SELECT 'yuki@qq.com', 'Creamy Mushroom Risotto', 'Saucepan'
  UNION ALL SELECT 'yuki@qq.com', 'Creamy Mushroom Risotto', 'Frying pan'
  UNION ALL SELECT 'yuki@qq.com', 'Handmade Egg Pasta with Mushrooms', 'Hob'
  UNION ALL SELECT 'yuki@qq.com', 'Handmade Egg Pasta with Mushrooms', 'Saucepan'
  UNION ALL SELECT 'yuki@qq.com', 'Handmade Egg Pasta with Mushrooms', 'Frying pan'
  UNION ALL SELECT 'yuki@qq.com', 'Handmade Egg Pasta with Mushrooms', 'Rolling pin'
) seed
JOIN users u ON u.email = seed.author_email
JOIN recipes r ON r.author_user_id = u.user_id AND r.title = seed.title
JOIN equipment e ON e.equipment_name = seed.equipment_name
WHERE NOT EXISTS (SELECT 1 FROM recipe_equipment re WHERE re.recipe_id = r.recipe_id);

COMMIT;
