-- UniMeal Planner frontend-alignment migration
-- Run once (or safely re-run) on an existing unimeal_planner database.
-- It preserves existing rows and adds only the fields needed by the current
-- Recipe Library / Dashboard integration.

USE unimeal_planner;

DROP PROCEDURE IF EXISTS apply_frontend_alignment;

DELIMITER //
CREATE PROCEDURE apply_frontend_alignment()
BEGIN
  DECLARE image_url_exists INT DEFAULT 0;
  DECLARE ingredient_cost_exists INT DEFAULT 0;
  DECLARE ingredient_cost_check_exists INT DEFAULT 0;

  SELECT COUNT(*) INTO image_url_exists
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'recipes'
    AND column_name = 'image_url';

  IF image_url_exists = 0 THEN
    ALTER TABLE recipes
      ADD COLUMN image_url VARCHAR(500) NULL AFTER title;
  END IF;

  SELECT COUNT(*) INTO ingredient_cost_exists
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'ingredients'
    AND column_name = 'estimated_unit_cost';

  IF ingredient_cost_exists = 0 THEN
    ALTER TABLE ingredients
      ADD COLUMN estimated_unit_cost DECIMAL(12,4) NOT NULL DEFAULT 0.0000
      AFTER default_measurement_unit_id;
  END IF;

  SELECT COUNT(*) INTO ingredient_cost_check_exists
  FROM information_schema.table_constraints
  WHERE constraint_schema = DATABASE()
    AND table_name = 'ingredients'
    AND constraint_name = 'ck_ingredients_estimated_unit_cost'
    AND constraint_type = 'CHECK';

  IF ingredient_cost_check_exists = 0 THEN
    ALTER TABLE ingredients
      ADD CONSTRAINT ck_ingredients_estimated_unit_cost
      CHECK (estimated_unit_cost >= 0);
  END IF;
END //
DELIMITER ;

CALL apply_frontend_alignment();
DROP PROCEDURE apply_frontend_alignment;

-- Keep the Recipe Library API read model in sync with master_schema.sql.
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
