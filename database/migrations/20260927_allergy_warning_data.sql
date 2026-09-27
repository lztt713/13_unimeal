-- Allergy-warning reference data and name hygiene for MySQL 8.0.16+.
-- Run after 20260923_frontend_equipment_and_allergens.sql. Back up an existing
-- database first. This script is repeatable and does not create recipe tags:
-- the API derives them from recipe_ingredients -> ingredient_allergens -> allergies.
USE unimeal_planner;

-- A duplicate normalized name may be referenced by recipes, shopping lists,
-- pantry items or users. Stop for a reviewed merge rather than deleting IDs.
DROP PROCEDURE IF EXISTS assert_allergy_warning_names;
DELIMITER //
CREATE PROCEDURE assert_allergy_warning_names()
BEGIN
  IF EXISTS (SELECT 1 FROM ingredients WHERE CHAR_LENGTH(TRIM(ingredient_name)) = 0)
    OR EXISTS (SELECT 1 FROM allergies WHERE CHAR_LENGTH(TRIM(allergy_name)) = 0) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blank ingredient or allergy name requires manual review';
  END IF;
  IF EXISTS (
    SELECT 1 FROM ingredients
    GROUP BY LOWER(TRIM(ingredient_name)) COLLATE utf8mb4_0900_ai_ci
    HAVING COUNT(*) > 1
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate normalized ingredient names require a reviewed ID merge';
  END IF;
  IF EXISTS (
    SELECT 1 FROM allergies
    WHERE LOWER(TRIM(allergy_name)) <> 'no known allergies'
    GROUP BY LOWER(TRIM(allergy_name)) COLLATE utf8mb4_0900_ai_ci
    HAVING COUNT(*) > 1
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate normalized allergy names require a reviewed ID merge';
  END IF;
END //
DELIMITER ;
CALL assert_allergy_warning_names();
DROP PROCEDURE assert_allergy_warning_names;

START TRANSACTION;

-- No row in user_allergies means that the user declared no known allergies.
-- Existing placeholder links are removed by the allergy FK's ON DELETE CASCADE.
DELETE FROM allergies WHERE LOWER(TRIM(allergy_name)) = 'no known allergies';

UPDATE allergies SET allergy_name = TRIM(allergy_name)
WHERE CHAR_LENGTH(allergy_name) <> CHAR_LENGTH(TRIM(allergy_name));
UPDATE ingredients SET ingredient_name = TRIM(ingredient_name)
WHERE CHAR_LENGTH(ingredient_name) <> CHAR_LENGTH(TRIM(ingredient_name));

-- Correct the display spelling of the supplied catalogue while keeping IDs.
UPDATE allergies a
JOIN (
  SELECT 'Dairy' AS name UNION ALL SELECT 'Egg' UNION ALL SELECT 'Peanut'
  UNION ALL SELECT 'Gluten' UNION ALL SELECT 'Wheat' UNION ALL SELECT 'Soy'
  UNION ALL SELECT 'Sesame' UNION ALL SELECT 'Tree Nuts'
  UNION ALL SELECT 'Fish' UNION ALL SELECT 'Shellfish'
) standard_name ON LOWER(a.allergy_name) = LOWER(standard_name.name)
SET a.allergy_name = standard_name.name
WHERE BINARY a.allergy_name <> BINARY standard_name.name;

UPDATE ingredients i
JOIN (
  SELECT 'Rice' AS name UNION ALL SELECT 'Tomato' UNION ALL SELECT 'Onion'
  UNION ALL SELECT 'Egg' UNION ALL SELECT 'Milk' UNION ALL SELECT 'Bread'
  UNION ALL SELECT 'Broccoli' UNION ALL SELECT 'Carrot' UNION ALL SELECT 'Chicken'
  UNION ALL SELECT 'Chickpeas' UNION ALL SELECT 'Coconut Milk' UNION ALL SELECT 'Cream'
  UNION ALL SELECT 'Cucumber' UNION ALL SELECT 'Cumin' UNION ALL SELECT 'Garlic'
  UNION ALL SELECT 'Hummus' UNION ALL SELECT 'Lentils' UNION ALL SELECT 'Mushrooms'
  UNION ALL SELECT 'Pasta' UNION ALL SELECT 'Wrap' UNION ALL SELECT 'Olive Oil'
  UNION ALL SELECT 'Risotto Rice' UNION ALL SELECT 'Vegetable Stock'
  UNION ALL SELECT 'Wheat Flour'
) standard_name ON LOWER(i.ingredient_name) = LOWER(standard_name.name)
SET i.ingredient_name = standard_name.name
WHERE BINARY i.ingredient_name <> BINARY standard_name.name;

INSERT INTO allergies (allergy_name)
SELECT standard_name.name
FROM (
  SELECT 'Dairy' AS name UNION ALL SELECT 'Egg' UNION ALL SELECT 'Peanut'
  UNION ALL SELECT 'Gluten' UNION ALL SELECT 'Wheat' UNION ALL SELECT 'Soy'
  UNION ALL SELECT 'Sesame' UNION ALL SELECT 'Tree Nuts'
  UNION ALL SELECT 'Fish' UNION ALL SELECT 'Shellfish'
) standard_name
WHERE NOT EXISTS (SELECT 1 FROM allergies a WHERE a.allergy_name = standard_name.name);

-- Positive facts for conventional seed ingredients only. Bread, Pasta, Wrap
-- and Wheat Flour in this project are wheat-based. Do not infer Dairy from the
-- name Coconut Milk. Hummus/Vegetable Stock need their product labels checked.
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
) known_mapping
JOIN ingredients i ON i.ingredient_name = known_mapping.ingredient_name
JOIN allergies a ON a.allergy_name = known_mapping.allergy_name
WHERE NOT EXISTS (
  SELECT 1 FROM ingredient_allergens ia
  WHERE ia.ingredient_id = i.ingredient_id AND ia.allergy_id = a.allergy_id
);

COMMIT;

-- Keep the existing UNIQUE keys and make their case-insensitive comparison
-- explicit even when an older database used a different default collation.
DROP PROCEDURE IF EXISTS apply_allergy_warning_name_rules;
DELIMITER //
CREATE PROCEDURE apply_allergy_warning_name_rules()
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'allergies'
      AND column_name = 'allergy_name' AND collation_name <> 'utf8mb4_0900_ai_ci'
  ) THEN
    ALTER TABLE allergies MODIFY COLUMN allergy_name VARCHAR(80)
      CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'ingredients'
      AND column_name = 'ingredient_name' AND collation_name <> 'utf8mb4_0900_ai_ci'
  ) THEN
    ALTER TABLE ingredients MODIFY COLUMN ingredient_name VARCHAR(120)
      CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'allergies'
      AND constraint_name = 'ck_allergies_name_valid' AND constraint_type = 'CHECK'
  ) THEN
    ALTER TABLE allergies ADD CONSTRAINT ck_allergies_name_valid CHECK (
      CHAR_LENGTH(TRIM(allergy_name)) > 0
      AND CHAR_LENGTH(allergy_name) = CHAR_LENGTH(TRIM(allergy_name))
      AND LOWER(allergy_name) <> 'no known allergies'
    );
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'ingredients'
      AND constraint_name = 'ck_ingredients_name_valid' AND constraint_type = 'CHECK'
  ) THEN
    ALTER TABLE ingredients ADD CONSTRAINT ck_ingredients_name_valid CHECK (
      CHAR_LENGTH(TRIM(ingredient_name)) > 0
      AND CHAR_LENGTH(ingredient_name) = CHAR_LENGTH(TRIM(ingredient_name))
    );
  END IF;
END //
DELIMITER ;
CALL apply_allergy_warning_name_rules();
DROP PROCEDURE apply_allergy_warning_name_rules;
