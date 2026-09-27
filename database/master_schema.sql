-- UniMeal Planner master MySQL schema
-- Owner: Qichen Hu (Database Architect)
-- Target: MySQL 8.0.16+ (CHECK constraints are enforced from this version)
-- This is the only schema-definition script. Propose schema changes through the DBA.

CREATE DATABASE IF NOT EXISTS unimeal_planner
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE unimeal_planner;

CREATE TABLE IF NOT EXISTS roles (
  role_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_roles_role_name (role_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
  user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id TINYINT UNSIGNED NOT NULL,
  email VARCHAR(254) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(80) NOT NULL,
  cooking_skill ENUM('beginner', 'intermediate', 'advanced') NOT NULL DEFAULT 'beginner',
  kitchen_access ENUM('none', 'limited', 'shared', 'full') NOT NULL DEFAULT 'shared',
  favourite_cuisines_note VARCHAR(255) NULL,
  weekly_budget DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(role_id),
  CONSTRAINT ck_users_email CHECK (email LIKE '%_@_%._%'),
  CONSTRAINT ck_users_password_hash CHECK (CHAR_LENGTH(password_hash) >= 20),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role_active (role_id, is_active)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cuisines (
  cuisine_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cuisine_name VARCHAR(60) NOT NULL,
  UNIQUE KEY uq_cuisines_name (cuisine_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dietary_tags (
  dietary_tag_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tag_name VARCHAR(60) NOT NULL,
  description VARCHAR(255) NULL,
  UNIQUE KEY uq_dietary_tags_name (tag_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_dietary_preferences (
  user_id BIGINT UNSIGNED NOT NULL,
  dietary_tag_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (user_id, dietary_tag_id),
  CONSTRAINT fk_udp_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_udp_tag FOREIGN KEY (dietary_tag_id) REFERENCES dietary_tags(dietary_tag_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS allergies (
  allergy_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  allergy_name VARCHAR(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  CONSTRAINT ck_allergies_name_valid CHECK (
    CHAR_LENGTH(TRIM(allergy_name)) > 0
    AND CHAR_LENGTH(allergy_name) = CHAR_LENGTH(TRIM(allergy_name))
    AND LOWER(allergy_name) <> 'no known allergies'
  ),
  UNIQUE KEY uq_allergies_name (allergy_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_allergies (
  user_id BIGINT UNSIGNED NOT NULL,
  allergy_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (user_id, allergy_id),
  CONSTRAINT fk_ua_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_ua_allergy FOREIGN KEY (allergy_id) REFERENCES allergies(allergy_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ingredient_categories (
  ingredient_category_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(60) NOT NULL,
  UNIQUE KEY uq_ingredient_categories_name (category_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS measurement_units (
  measurement_unit_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  unit_name VARCHAR(40) NOT NULL,
  unit_symbol VARCHAR(12) NOT NULL,
  unit_type ENUM('weight', 'volume', 'count', 'other') NOT NULL,
  UNIQUE KEY uq_measurement_units_name (unit_name),
  UNIQUE KEY uq_measurement_units_symbol (unit_symbol)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ingredients (
  ingredient_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ingredient_category_id SMALLINT UNSIGNED NOT NULL,
  ingredient_name VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  default_measurement_unit_id SMALLINT UNSIGNED NULL,
  estimated_unit_cost DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_ingredients_category FOREIGN KEY (ingredient_category_id) REFERENCES ingredient_categories(ingredient_category_id),
  CONSTRAINT fk_ingredients_default_unit FOREIGN KEY (default_measurement_unit_id) REFERENCES measurement_units(measurement_unit_id),
  CONSTRAINT ck_ingredients_estimated_unit_cost CHECK (estimated_unit_cost >= 0),
  CONSTRAINT ck_ingredients_name_valid CHECK (
    CHAR_LENGTH(TRIM(ingredient_name)) > 0
    AND CHAR_LENGTH(ingredient_name) = CHAR_LENGTH(TRIM(ingredient_name))
  ),
  UNIQUE KEY uq_ingredients_name (ingredient_name),
  KEY idx_ingredients_category_active (ingredient_category_id, is_active)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ingredient_allergens (
  ingredient_id BIGINT UNSIGNED NOT NULL,
  allergy_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (ingredient_id, allergy_id),
  CONSTRAINT fk_ia_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
  CONSTRAINT fk_ia_allergy FOREIGN KEY (allergy_id) REFERENCES allergies(allergy_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS equipment (
  equipment_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  equipment_name VARCHAR(80) NOT NULL,
  description VARCHAR(255) NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT ck_equipment_name CHECK (CHAR_LENGTH(TRIM(equipment_name)) > 0),
  UNIQUE KEY uq_equipment_name (equipment_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipes (
  recipe_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  author_user_id BIGINT UNSIGNED NOT NULL,
  cuisine_id SMALLINT UNSIGNED NULL,
  title VARCHAR(160) NOT NULL,
  image_url VARCHAR(500) NULL,
  description TEXT NULL,
  preparation_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  cooking_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  servings TINYINT UNSIGNED NOT NULL,
  difficulty ENUM('easy', 'medium', 'hard') NOT NULL DEFAULT 'easy',
  estimated_cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  status ENUM('draft', 'published', 'archived') NOT NULL DEFAULT 'draft',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_recipes_author FOREIGN KEY (author_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_recipes_cuisine FOREIGN KEY (cuisine_id) REFERENCES cuisines(cuisine_id) ON DELETE SET NULL,
  CONSTRAINT ck_recipes_servings CHECK (servings BETWEEN 1 AND 50),
  CONSTRAINT ck_recipes_cost CHECK (estimated_cost >= 0),
  KEY idx_recipes_discovery (status, difficulty, estimated_cost),
  KEY idx_recipes_author (author_user_id),
  KEY idx_recipes_cuisine (cuisine_id),
  FULLTEXT KEY ft_recipes_title_description (title, description)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipe_equipment (
  recipe_id BIGINT UNSIGNED NOT NULL,
  equipment_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (recipe_id, equipment_id),
  CONSTRAINT fk_recipe_equipment_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
  CONSTRAINT fk_recipe_equipment_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE RESTRICT,
  KEY idx_recipe_equipment_equipment (equipment_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipe_dietary_tags (
  recipe_id BIGINT UNSIGNED NOT NULL,
  dietary_tag_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (recipe_id, dietary_tag_id),
  CONSTRAINT fk_rdt_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
  CONSTRAINT fk_rdt_tag FOREIGN KEY (dietary_tag_id) REFERENCES dietary_tags(dietary_tag_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipe_ingredients (
  recipe_ingredient_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recipe_id BIGINT UNSIGNED NOT NULL,
  ingredient_id BIGINT UNSIGNED NOT NULL,
  measurement_unit_id SMALLINT UNSIGNED NOT NULL,
  quantity DECIMAL(10,3) NOT NULL,
  preparation_note VARCHAR(160) NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  CONSTRAINT fk_ri_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
  CONSTRAINT fk_ri_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id),
  CONSTRAINT fk_ri_unit FOREIGN KEY (measurement_unit_id) REFERENCES measurement_units(measurement_unit_id),
  CONSTRAINT ck_ri_quantity CHECK (quantity > 0),
  CONSTRAINT ck_ri_sort_order CHECK (sort_order > 0),
  UNIQUE KEY uq_recipe_ingredients_line (recipe_id, ingredient_id, measurement_unit_id, sort_order),
  KEY idx_ri_ingredient (ingredient_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipe_steps (
  recipe_step_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recipe_id BIGINT UNSIGNED NOT NULL,
  step_number SMALLINT UNSIGNED NOT NULL,
  instruction TEXT NOT NULL,
  CONSTRAINT fk_recipe_steps_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
  CONSTRAINT ck_recipe_steps_number CHECK (step_number > 0),
  UNIQUE KEY uq_recipe_steps_order (recipe_id, step_number)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS saved_recipes (
  user_id BIGINT UNSIGNED NOT NULL,
  recipe_id BIGINT UNSIGNED NOT NULL,
  saved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, recipe_id),
  CONSTRAINT fk_saved_recipes_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_saved_recipes_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipe_ratings (
  user_id BIGINT UNSIGNED NOT NULL,
  recipe_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, recipe_id),
  CONSTRAINT fk_recipe_ratings_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_recipe_ratings_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
  CONSTRAINT ck_recipe_ratings_value CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipe_comments (
  recipe_comment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recipe_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  comment_text TEXT NOT NULL,
  is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_recipe_comments_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
  CONSTRAINT fk_recipe_comments_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT ck_recipe_comments_text CHECK (CHAR_LENGTH(TRIM(comment_text)) > 0),
  KEY idx_recipe_comments_recipe_created (recipe_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS budget_periods (
  budget_period_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  budget_amount DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_budget_periods_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT ck_budget_periods_dates CHECK (period_end >= period_start),
  CONSTRAINT ck_budget_periods_amount CHECK (budget_amount >= 0),
  UNIQUE KEY uq_budget_periods_user_dates (user_id, period_start, period_end)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS meal_plans (
  meal_plan_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  week_start_date DATE NOT NULL,
  plan_name VARCHAR(100) NOT NULL DEFAULT 'Weekly meal plan',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_meal_plans_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE KEY uq_meal_plans_user_week (user_id, week_start_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS meal_plan_entries (
  meal_plan_entry_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  meal_plan_id BIGINT UNSIGNED NOT NULL,
  recipe_id BIGINT UNSIGNED NOT NULL,
  planned_date DATE NOT NULL,
  meal_type ENUM('breakfast', 'lunch', 'dinner', 'snack') NOT NULL,
  servings TINYINT UNSIGNED NOT NULL,
  notes VARCHAR(500) NULL,
  CONSTRAINT fk_mpe_meal_plan FOREIGN KEY (meal_plan_id) REFERENCES meal_plans(meal_plan_id) ON DELETE CASCADE,
  CONSTRAINT fk_mpe_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id),
  CONSTRAINT ck_mpe_servings CHECK (servings BETWEEN 1 AND 50),
  UNIQUE KEY uq_mpe_slot (meal_plan_id, planned_date, meal_type),
  KEY idx_mpe_recipe_date (recipe_id, planned_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS shopping_lists (
  shopping_list_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  meal_plan_id BIGINT UNSIGNED NULL,
  list_name VARCHAR(100) NOT NULL DEFAULT 'Shopping list',
  status ENUM('active', 'completed', 'archived') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_shopping_lists_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_shopping_lists_meal_plan FOREIGN KEY (meal_plan_id) REFERENCES meal_plans(meal_plan_id) ON DELETE SET NULL,
  KEY idx_shopping_lists_user_status (user_id, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS shopping_list_items (
  shopping_list_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  shopping_list_id BIGINT UNSIGNED NOT NULL,
  ingredient_id BIGINT UNSIGNED NULL,
  measurement_unit_id SMALLINT UNSIGNED NOT NULL,
  item_name VARCHAR(160) NOT NULL,
  quantity DECIMAL(10,3) NOT NULL,
  estimated_unit_cost DECIMAL(10,2) NULL,
  actual_cost DECIMAL(10,2) NULL,
  is_purchased BOOLEAN NOT NULL DEFAULT FALSE,
  purchased_at TIMESTAMP NULL,
  CONSTRAINT fk_sli_list FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(shopping_list_id) ON DELETE CASCADE,
  CONSTRAINT fk_sli_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE SET NULL,
  CONSTRAINT fk_sli_unit FOREIGN KEY (measurement_unit_id) REFERENCES measurement_units(measurement_unit_id),
  CONSTRAINT ck_sli_quantity CHECK (quantity > 0),
  CONSTRAINT ck_sli_estimated_cost CHECK (estimated_unit_cost IS NULL OR estimated_unit_cost >= 0),
  CONSTRAINT ck_sli_actual_cost CHECK (actual_cost IS NULL OR actual_cost >= 0),
  CONSTRAINT ck_sli_purchase_time CHECK ((is_purchased = FALSE AND purchased_at IS NULL) OR (is_purchased = TRUE AND purchased_at IS NOT NULL)),
  KEY idx_sli_list_purchased (shopping_list_id, is_purchased)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pantry_items (
  pantry_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  ingredient_id BIGINT UNSIGNED NOT NULL,
  measurement_unit_id SMALLINT UNSIGNED NOT NULL,
  quantity DECIMAL(10,3) NOT NULL,
  expiry_date DATE NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pantry_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_pantry_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id),
  CONSTRAINT fk_pantry_unit FOREIGN KEY (measurement_unit_id) REFERENCES measurement_units(measurement_unit_id),
  CONSTRAINT ck_pantry_quantity CHECK (quantity >= 0),
  UNIQUE KEY uq_pantry_item (user_id, ingredient_id, measurement_unit_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
  notification_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  notification_type ENUM('meal_reminder', 'shopping_reminder', 'recipe_update', 'system') NOT NULL,
  title VARCHAR(160) NOT NULL,
  message TEXT NOT NULL,
  dedupe_key VARCHAR(255) NULL,
  scheduled_for TIMESTAMP NULL,
  read_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  KEY idx_notifications_user_read_scheduled (user_id, read_at, scheduled_for)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS content_reports (
  content_report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reporter_user_id BIGINT UNSIGNED NOT NULL,
  recipe_id BIGINT UNSIGNED NULL,
  recipe_comment_id BIGINT UNSIGNED NULL,
  reason VARCHAR(255) NOT NULL,
  status ENUM('open', 'reviewing', 'resolved', 'dismissed') NOT NULL DEFAULT 'open',
  reviewed_by_user_id BIGINT UNSIGNED NULL,
  reviewed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reports_reporter FOREIGN KEY (reporter_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_reports_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_comment FOREIGN KEY (recipe_comment_id) REFERENCES recipe_comments(recipe_comment_id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_reviewer FOREIGN KEY (reviewed_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
  CONSTRAINT ck_reports_subject CHECK ((recipe_id IS NOT NULL) <> (recipe_comment_id IS NOT NULL)),
  KEY idx_reports_status_created (status, created_at)
) ENGINE=InnoDB;

-- Read model for the current Recipe Library cards. It keeps the tables
-- normalised while giving the API one predictable source for card fields.
-- `estimated_recipe_cost` is the whole recipe cost; the API should expose
-- `estimated_cost_per_serving` where the UI says "Price per serving".
CREATE OR REPLACE VIEW vw_recipe_cards AS
SELECT
  r.recipe_id AS id,
  r.title,
  r.image_url,
  COALESCE(c.cuisine_name, 'Unclassified') AS cuisine,
  CASE r.difficulty
    WHEN 'easy' THEN 'Easy'
    WHEN 'medium' THEN 'Medium'
    WHEN 'hard' THEN 'Hard'
  END AS difficulty,
  r.estimated_cost AS estimated_recipe_cost,
  ROUND(r.estimated_cost / NULLIF(r.servings, 0), 2) AS estimated_cost_per_serving,
  r.preparation_minutes + r.cooking_minutes AS cook_time,
  COALESCE((
    SELECT ROUND(AVG(rr.rating), 1)
    FROM recipe_ratings rr
    WHERE rr.recipe_id = r.recipe_id
  ), 0.0) AS rating,
  (
    SELECT COUNT(*)
    FROM recipe_ratings rr
    WHERE rr.recipe_id = r.recipe_id
  ) AS review_count,
  COALESCE((
    SELECT GROUP_CONCAT(dt.tag_name ORDER BY dt.tag_name SEPARATOR ', ')
    FROM recipe_dietary_tags rdt
    JOIN dietary_tags dt ON dt.dietary_tag_id = rdt.dietary_tag_id
    WHERE rdt.recipe_id = r.recipe_id
  ), '') AS dietary_tags
FROM recipes r
LEFT JOIN cuisines c ON c.cuisine_id = r.cuisine_id
WHERE r.status = 'published';

INSERT INTO roles (role_name) VALUES ('student'), ('contributor'), ('administrator')
ON DUPLICATE KEY UPDATE role_name = VALUES(role_name);

INSERT INTO measurement_units (unit_name, unit_symbol, unit_type) VALUES
  ('gram', 'g', 'weight'),
  ('kilogram', 'kg', 'weight'),
  ('millilitre', 'ml', 'volume'),
  ('litre', 'L', 'volume'),
  ('piece', 'pc', 'count'),
  ('tablespoon', 'tbsp', 'volume'),
  ('teaspoon', 'tsp', 'volume'),
  ('cup', 'cup', 'volume')
ON DUPLICATE KEY UPDATE unit_type = VALUES(unit_type);
