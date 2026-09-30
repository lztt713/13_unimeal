-- Distinguish six similar demonstration recipes without replacing their IDs or user activity.
-- Apply after the 20260929 recipe seed and image/comment migrations.
-- A recipe is revised only while its original author, description, image, ingredients,
-- and steps still match the demonstration data. Re-running this file leaves edits alone.
USE unimeal_planner;
START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS distinct_recipe_revision;
CREATE TEMPORARY TABLE distinct_recipe_revision (
  old_title VARCHAR(160) NOT NULL PRIMARY KEY,
  new_title VARCHAR(160) NOT NULL,
  old_cuisine VARCHAR(80) NOT NULL,
  new_cuisine VARCHAR(80) NOT NULL,
  old_difficulty ENUM('easy', 'medium', 'hard') NOT NULL,
  new_difficulty ENUM('easy', 'medium', 'hard') NOT NULL,
  old_description TEXT NOT NULL,
  new_description TEXT NOT NULL,
  old_image_url VARCHAR(500) NOT NULL,
  new_image_url VARCHAR(500) NOT NULL,
  old_estimated_cost DECIMAL(10,2) NOT NULL,
  new_estimated_cost DECIMAL(10,2) NOT NULL,
  old_ingredient_count SMALLINT UNSIGNED NOT NULL,
  new_ingredient_count SMALLINT UNSIGNED NOT NULL,
  old_step_count SMALLINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

INSERT INTO distinct_recipe_revision VALUES
  ('Cumin Chickpea Rice Skillet', 'Cumin Chickpea Rice Skillet', 'Indian', 'Indian', 'easy', 'easy',
   'A one-pan chickpea rice skillet with tomato, cumin and coconut milk.',
   'Dry-fried cumin chickpea rice with broccoli and carrot for a colourful vegetable skillet.',
   '/images/recipes/cumin-chickpea-rice-skillet-20260929.png',
   '/images/recipes/cumin-chickpea-rice-skillet-20260929.png', 3.16, 3.08, 8, 8, 4),
  ('Tomato Egg Pasta', 'Broccoli Egg Frittata', 'European', 'European', 'medium', 'medium',
   'Tomato pasta finished with softly cooked egg for extra protein.',
   'A stovetop broccoli and egg frittata with tender onion and a splash of milk.',
   '/images/recipes/tomato-egg-pasta-20260929.png',
   '/images/recipes/broccoli-egg-frittata-20260930.png', 4.05, 3.40, 6, 5, 4),
  ('Creamy Chicken Mushroom Pasta', 'Chicken Mushroom Wraps', 'European', 'European', 'medium', 'medium',
   'Creamy chicken and mushroom pasta for a satisfying high-protein dinner.',
   'Warm chicken and mushroom wraps with tender carrot and onion for an easy hand-held dinner.',
   '/images/recipes/creamy-chicken-mushroom-pasta-20260929.png',
   '/images/recipes/chicken-mushroom-wraps-20260930.png', 4.95, 4.27, 7, 6, 4),
  ('Garlic Mushroom Rice Skillet', 'Creamy Mushroom Soup', 'Chinese', 'European', 'easy', 'easy',
   'A simple mushroom and vegetable rice skillet with garlic and olive oil.',
   'A comforting mushroom soup made creamy with milk and vegetable stock.',
   '/images/recipes/garlic-mushroom-rice-skillet-20260929.png',
   '/images/recipes/creamy-mushroom-soup-20260930.png', 2.70, 3.32, 6, 6, 4),
  ('Garlic Tomato Pasta', 'Carrot Hummus Pasta', 'Italian', 'Mediterranean', 'easy', 'easy',
   'A low-cost pasta dinner with garlic, tomato and olive oil for a busy student evening.',
   'A quick pasta coated in a creamy hummus sauce with sweet carrot and garlic.',
   '/images/recipes/garlic-tomato-pasta-20260929.png',
   '/images/recipes/carrot-hummus-pasta-20260930.png', 2.80, 2.66, 5, 5, 4),
  ('Mushroom Lentil Risotto', 'Lentil Carrot Patties', 'Italian', 'Middle Eastern', 'hard', 'medium',
   'A slow-cooked mushroom and lentil risotto with vegetable stock.',
   'Pan-fried lentil and carrot patties with onion, garlic and egg to bind them.',
   '/images/recipes/mushroom-lentil-risotto-20260929.png',
   '/images/recipes/lentil-carrot-patties-20260930.png', 3.82, 2.23, 7, 6, 5);

DROP TEMPORARY TABLE IF EXISTS distinct_recipe_ingredient;
CREATE TEMPORARY TABLE distinct_recipe_ingredient (
  recipe_title VARCHAR(160) NOT NULL,
  phase ENUM('old', 'new') NOT NULL,
  ingredient_name VARCHAR(120) NOT NULL,
  unit_symbol VARCHAR(12) NOT NULL,
  quantity DECIMAL(10,3) NOT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL,
  preparation_note VARCHAR(160) NULL,
  PRIMARY KEY (recipe_title, phase, sort_order)
) ENGINE=InnoDB;

INSERT INTO distinct_recipe_ingredient VALUES
  ('Cumin Chickpea Rice Skillet', 'old', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Cumin Chickpea Rice Skillet', 'old', 'Chickpeas', 'g', 240.000, 2, 'cooked and drained'),
  ('Cumin Chickpea Rice Skillet', 'old', 'Coconut Milk', 'ml', 120.000, 3, NULL),
  ('Cumin Chickpea Rice Skillet', 'old', 'Tomato', 'pc', 2.000, 4, 'chopped'),
  ('Cumin Chickpea Rice Skillet', 'old', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Cumin Chickpea Rice Skillet', 'old', 'Garlic', 'pc', 2.000, 6, 'minced'),
  ('Cumin Chickpea Rice Skillet', 'old', 'Cumin', 'tsp', 1.000, 7, NULL),
  ('Cumin Chickpea Rice Skillet', 'old', 'Olive Oil', 'ml', 10.000, 8, NULL),
  ('Cumin Chickpea Rice Skillet', 'new', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Cumin Chickpea Rice Skillet', 'new', 'Chickpeas', 'g', 240.000, 2, 'cooked and drained'),
  ('Cumin Chickpea Rice Skillet', 'new', 'Broccoli', 'g', 200.000, 3, 'small florets'),
  ('Cumin Chickpea Rice Skillet', 'new', 'Carrot', 'pc', 1.000, 4, 'finely diced'),
  ('Cumin Chickpea Rice Skillet', 'new', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Cumin Chickpea Rice Skillet', 'new', 'Garlic', 'pc', 2.000, 6, 'minced'),
  ('Cumin Chickpea Rice Skillet', 'new', 'Cumin', 'tsp', 1.000, 7, NULL),
  ('Cumin Chickpea Rice Skillet', 'new', 'Olive Oil', 'ml', 10.000, 8, NULL),
  ('Tomato Egg Pasta', 'old', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Tomato Egg Pasta', 'old', 'Egg', 'pc', 4.000, 2, 'beaten'),
  ('Tomato Egg Pasta', 'old', 'Tomato', 'pc', 3.000, 3, 'chopped'),
  ('Tomato Egg Pasta', 'old', 'Garlic', 'pc', 2.000, 4, 'minced'),
  ('Tomato Egg Pasta', 'old', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Tomato Egg Pasta', 'old', 'Olive Oil', 'ml', 10.000, 6, NULL),
  ('Tomato Egg Pasta', 'new', 'Egg', 'pc', 4.000, 1, 'beaten'),
  ('Tomato Egg Pasta', 'new', 'Broccoli', 'g', 200.000, 2, 'small florets'),
  ('Tomato Egg Pasta', 'new', 'Onion', 'pc', 1.000, 3, 'diced'),
  ('Tomato Egg Pasta', 'new', 'Milk', 'ml', 40.000, 4, NULL),
  ('Tomato Egg Pasta', 'new', 'Olive Oil', 'ml', 10.000, 5, NULL),
  ('Creamy Chicken Mushroom Pasta', 'old', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Creamy Chicken Mushroom Pasta', 'old', 'Chicken', 'g', 250.000, 2, 'bite-size pieces'),
  ('Creamy Chicken Mushroom Pasta', 'old', 'Mushrooms', 'g', 200.000, 3, 'sliced'),
  ('Creamy Chicken Mushroom Pasta', 'old', 'Cream', 'ml', 120.000, 4, NULL),
  ('Creamy Chicken Mushroom Pasta', 'old', 'Milk', 'ml', 100.000, 5, NULL),
  ('Creamy Chicken Mushroom Pasta', 'old', 'Garlic', 'pc', 2.000, 6, 'minced'),
  ('Creamy Chicken Mushroom Pasta', 'old', 'Olive Oil', 'ml', 10.000, 7, NULL),
  ('Creamy Chicken Mushroom Pasta', 'new', 'Wrap', 'pc', 2.000, 1, NULL),
  ('Creamy Chicken Mushroom Pasta', 'new', 'Chicken', 'g', 200.000, 2, 'bite-size pieces'),
  ('Creamy Chicken Mushroom Pasta', 'new', 'Mushrooms', 'g', 150.000, 3, 'sliced'),
  ('Creamy Chicken Mushroom Pasta', 'new', 'Carrot', 'pc', 1.000, 4, 'grated'),
  ('Creamy Chicken Mushroom Pasta', 'new', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Creamy Chicken Mushroom Pasta', 'new', 'Olive Oil', 'ml', 10.000, 6, NULL),
  ('Garlic Mushroom Rice Skillet', 'old', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Garlic Mushroom Rice Skillet', 'old', 'Mushrooms', 'g', 200.000, 2, 'sliced'),
  ('Garlic Mushroom Rice Skillet', 'old', 'Garlic', 'pc', 2.000, 3, 'minced'),
  ('Garlic Mushroom Rice Skillet', 'old', 'Onion', 'pc', 1.000, 4, 'diced'),
  ('Garlic Mushroom Rice Skillet', 'old', 'Carrot', 'pc', 1.000, 5, 'thinly sliced'),
  ('Garlic Mushroom Rice Skillet', 'old', 'Olive Oil', 'ml', 10.000, 6, NULL),
  ('Garlic Mushroom Rice Skillet', 'new', 'Mushrooms', 'g', 250.000, 1, 'sliced'),
  ('Garlic Mushroom Rice Skillet', 'new', 'Milk', 'ml', 200.000, 2, NULL),
  ('Garlic Mushroom Rice Skillet', 'new', 'Vegetable Stock', 'ml', 300.000, 3, NULL),
  ('Garlic Mushroom Rice Skillet', 'new', 'Onion', 'pc', 1.000, 4, 'diced'),
  ('Garlic Mushroom Rice Skillet', 'new', 'Garlic', 'pc', 2.000, 5, 'minced'),
  ('Garlic Mushroom Rice Skillet', 'new', 'Olive Oil', 'ml', 10.000, 6, NULL),
  ('Garlic Tomato Pasta', 'old', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Garlic Tomato Pasta', 'old', 'Tomato', 'pc', 3.000, 2, 'chopped'),
  ('Garlic Tomato Pasta', 'old', 'Garlic', 'pc', 2.000, 3, 'minced'),
  ('Garlic Tomato Pasta', 'old', 'Onion', 'pc', 1.000, 4, 'diced'),
  ('Garlic Tomato Pasta', 'old', 'Olive Oil', 'ml', 10.000, 5, NULL),
  ('Garlic Tomato Pasta', 'new', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Garlic Tomato Pasta', 'new', 'Carrot', 'pc', 2.000, 2, 'finely grated'),
  ('Garlic Tomato Pasta', 'new', 'Hummus', 'g', 120.000, 3, NULL),
  ('Garlic Tomato Pasta', 'new', 'Garlic', 'pc', 2.000, 4, 'minced'),
  ('Garlic Tomato Pasta', 'new', 'Olive Oil', 'ml', 10.000, 5, NULL),
  ('Mushroom Lentil Risotto', 'old', 'Risotto Rice', 'g', 180.000, 1, NULL),
  ('Mushroom Lentil Risotto', 'old', 'Lentils', 'g', 120.000, 2, 'rinsed'),
  ('Mushroom Lentil Risotto', 'old', 'Mushrooms', 'g', 200.000, 3, 'sliced'),
  ('Mushroom Lentil Risotto', 'old', 'Vegetable Stock', 'ml', 700.000, 4, 'kept warm'),
  ('Mushroom Lentil Risotto', 'old', 'Onion', 'pc', 1.000, 5, 'finely diced'),
  ('Mushroom Lentil Risotto', 'old', 'Garlic', 'pc', 2.000, 6, 'minced'),
  ('Mushroom Lentil Risotto', 'old', 'Olive Oil', 'ml', 10.000, 7, NULL),
  ('Mushroom Lentil Risotto', 'new', 'Lentils', 'g', 200.000, 1, 'rinsed'),
  ('Mushroom Lentil Risotto', 'new', 'Carrot', 'pc', 2.000, 2, 'grated'),
  ('Mushroom Lentil Risotto', 'new', 'Onion', 'pc', 1.000, 3, 'diced'),
  ('Mushroom Lentil Risotto', 'new', 'Egg', 'pc', 1.000, 4, 'beaten'),
  ('Mushroom Lentil Risotto', 'new', 'Garlic', 'pc', 2.000, 5, 'minced'),
  ('Mushroom Lentil Risotto', 'new', 'Olive Oil', 'ml', 15.000, 6, NULL);

DROP TEMPORARY TABLE IF EXISTS distinct_recipe_step;
CREATE TEMPORARY TABLE distinct_recipe_step (
  recipe_title VARCHAR(160) NOT NULL,
  phase ENUM('old', 'new') NOT NULL,
  step_number SMALLINT UNSIGNED NOT NULL,
  instruction TEXT NOT NULL,
  PRIMARY KEY (recipe_title, phase, step_number)
) ENGINE=InnoDB;

INSERT INTO distinct_recipe_step VALUES
  ('Cumin Chickpea Rice Skillet', 'old', 1, 'Cook the rice in a saucepan until tender.'),
  ('Cumin Chickpea Rice Skillet', 'old', 2, 'Cook onion, garlic and cumin in olive oil in a frying pan.'),
  ('Cumin Chickpea Rice Skillet', 'old', 3, 'Add tomato, chickpeas and coconut milk, then simmer until thickened.'),
  ('Cumin Chickpea Rice Skillet', 'old', 4, 'Fold in the rice, heat through and serve.'),
  ('Cumin Chickpea Rice Skillet', 'new', 1, 'Cook the rice in a saucepan until tender, then let it cool briefly so the grains separate.'),
  ('Cumin Chickpea Rice Skillet', 'new', 2, 'Fry the onion, garlic, carrot and broccoli in olive oil until the vegetables are nearly tender.'),
  ('Cumin Chickpea Rice Skillet', 'new', 3, 'Add the drained chickpeas and cumin; cook until the chickpeas are dry and lightly browned.'),
  ('Cumin Chickpea Rice Skillet', 'new', 4, 'Fold in the rice and stir-fry until hot, then season to taste and serve.'),
  ('Tomato Egg Pasta', 'old', 1, 'Cook the pasta in a saucepan until tender.'),
  ('Tomato Egg Pasta', 'old', 2, 'Cook onion and garlic in olive oil in a frying pan until soft.'),
  ('Tomato Egg Pasta', 'old', 3, 'Add tomato and simmer until it forms a quick sauce.'),
  ('Tomato Egg Pasta', 'old', 4, 'Stir in beaten egg and pasta, cooking gently until the egg is set.'),
  ('Tomato Egg Pasta', 'new', 1, 'Cut the broccoli into small florets, boil until just tender, then drain well.'),
  ('Tomato Egg Pasta', 'new', 2, 'Cook the diced onion in olive oil in a frying pan until soft, then add the broccoli.'),
  ('Tomato Egg Pasta', 'new', 3, 'Whisk the eggs with the milk and pour the mixture evenly into the pan.'),
  ('Tomato Egg Pasta', 'new', 4, 'Cover and cook over low heat until the egg is fully set, then cut into wedges and serve.'),
  ('Creamy Chicken Mushroom Pasta', 'old', 1, 'Cook the pasta in a saucepan until tender.'),
  ('Creamy Chicken Mushroom Pasta', 'old', 2, 'Cook chicken, mushrooms and garlic in olive oil until the chicken is fully cooked.'),
  ('Creamy Chicken Mushroom Pasta', 'old', 3, 'Add milk and cream, then simmer briefly until lightly thickened.'),
  ('Creamy Chicken Mushroom Pasta', 'old', 4, 'Toss the pasta through the sauce and serve immediately.'),
  ('Creamy Chicken Mushroom Pasta', 'new', 1, 'Cook the chicken pieces in olive oil in a frying pan until browned and fully cooked.'),
  ('Creamy Chicken Mushroom Pasta', 'new', 2, 'Add mushrooms, onion and grated carrot; cook until the vegetables are tender and any liquid has evaporated.'),
  ('Creamy Chicken Mushroom Pasta', 'new', 3, 'Toss the chicken and vegetables together and divide the warm filling between two wraps.'),
  ('Creamy Chicken Mushroom Pasta', 'new', 4, 'Fold in the sides, roll each wrap tightly and serve.'),
  ('Garlic Mushroom Rice Skillet', 'old', 1, 'Cook the rice in a saucepan until tender.'),
  ('Garlic Mushroom Rice Skillet', 'old', 2, 'Cook onion, carrot, mushrooms and garlic in olive oil in a frying pan.'),
  ('Garlic Mushroom Rice Skillet', 'old', 3, 'Continue cooking until the mushrooms are browned and the vegetables are soft.'),
  ('Garlic Mushroom Rice Skillet', 'old', 4, 'Fold in the rice, warm through and serve.'),
  ('Garlic Mushroom Rice Skillet', 'new', 1, 'Brown the sliced mushrooms with onion and garlic in olive oil in a frying pan.'),
  ('Garlic Mushroom Rice Skillet', 'new', 2, 'Transfer to a saucepan, add vegetable stock and simmer until the mushrooms are very tender.'),
  ('Garlic Mushroom Rice Skillet', 'new', 3, 'Mash some mushrooms against the side of the pan to thicken the soup, then stir in milk and warm gently.'),
  ('Garlic Mushroom Rice Skillet', 'new', 4, 'Season to taste, ladle into bowls and serve warm.'),
  ('Garlic Tomato Pasta', 'old', 1, 'Boil the pasta in water until just tender, then reserve a little cooking water.'),
  ('Garlic Tomato Pasta', 'old', 2, 'Warm olive oil in a frying pan and cook the onion and garlic until softened.'),
  ('Garlic Tomato Pasta', 'old', 3, 'Add the chopped tomatoes and simmer until they make a quick sauce.'),
  ('Garlic Tomato Pasta', 'old', 4, 'Toss the pasta through the sauce, loosening with reserved water if needed.'),
  ('Garlic Tomato Pasta', 'new', 1, 'Cook the pasta until just tender, reserving some cooking water before draining.'),
  ('Garlic Tomato Pasta', 'new', 2, 'Soften the finely grated carrot and minced garlic in olive oil in a frying pan.'),
  ('Garlic Tomato Pasta', 'new', 3, 'Stir hummus with a little warm pasta water until it forms a smooth sauce.'),
  ('Garlic Tomato Pasta', 'new', 4, 'Toss the pasta with the carrot and hummus sauce, adding more pasta water if needed.'),
  ('Mushroom Lentil Risotto', 'old', 1, 'Cook onion, garlic and mushrooms in olive oil in a saucepan until softened.'),
  ('Mushroom Lentil Risotto', 'old', 2, 'Add risotto rice and stir for one minute to coat it in the oil.'),
  ('Mushroom Lentil Risotto', 'old', 3, 'Add warm stock gradually, stirring after each addition is absorbed.'),
  ('Mushroom Lentil Risotto', 'old', 4, 'Add lentils halfway through and continue cooking until the rice is creamy and tender.'),
  ('Mushroom Lentil Risotto', 'old', 5, 'Rest for two minutes before serving.'),
  ('Mushroom Lentil Risotto', 'new', 1, 'Boil the rinsed lentils until tender, then drain thoroughly and mash them coarsely.'),
  ('Mushroom Lentil Risotto', 'new', 2, 'Soften the onion, grated carrot and garlic in a little olive oil, then let them cool slightly.'),
  ('Mushroom Lentil Risotto', 'new', 3, 'Mix the vegetables with the mashed lentils and beaten egg until the mixture holds together.'),
  ('Mushroom Lentil Risotto', 'new', 4, 'Shape the mixture into small, firm patties and let them rest for a few minutes.'),
  ('Mushroom Lentil Risotto', 'new', 5, 'Pan-fry the patties in the remaining olive oil until browned on both sides and cooked through.');

-- Match every original line so later user edits do not get replaced on re-application.
-- Also require every replacement ingredient and unit to exist before deleting old lines.
DROP TEMPORARY TABLE IF EXISTS distinct_recipe_selected;
CREATE TEMPORARY TABLE distinct_recipe_selected (
  recipe_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  old_title VARCHAR(160) NOT NULL,
  old_ingredient_count SMALLINT UNSIGNED NOT NULL,
  new_ingredient_count SMALLINT UNSIGNED NOT NULL,
  old_step_count SMALLINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

INSERT INTO distinct_recipe_selected (
  recipe_id, old_title, old_ingredient_count, new_ingredient_count, old_step_count
)
SELECT recipe.recipe_id, revision.old_title, revision.old_ingredient_count,
       revision.new_ingredient_count, revision.old_step_count
FROM distinct_recipe_revision revision
JOIN recipes recipe ON BINARY recipe.title = BINARY revision.old_title
JOIN users author ON author.user_id = recipe.author_user_id
JOIN cuisines old_cuisine ON old_cuisine.cuisine_id = recipe.cuisine_id
  AND BINARY old_cuisine.cuisine_name = BINARY revision.old_cuisine
JOIN cuisines new_cuisine ON BINARY new_cuisine.cuisine_name = BINARY revision.new_cuisine
WHERE author.email = 'yuki@qq.com'
  AND recipe.status = 'published'
  AND recipe.difficulty = revision.old_difficulty
  AND BINARY recipe.description = BINARY revision.old_description
  AND BINARY recipe.image_url = BINARY revision.old_image_url
  AND recipe.estimated_cost = revision.old_estimated_cost
  AND NOT EXISTS (
    SELECT 1 FROM recipes other
    WHERE other.recipe_id <> recipe.recipe_id
      AND BINARY other.title = BINARY revision.new_title
  );

-- Each statement below opens each temporary seed table at most once (MySQL 1137).
-- Equal total and matching counts imply the complete original line set is unchanged.
DELETE selected FROM distinct_recipe_selected selected
LEFT JOIN (
  SELECT recipe_id, COUNT(*) AS line_count
  FROM recipe_ingredients GROUP BY recipe_id
) actual ON actual.recipe_id = selected.recipe_id
WHERE COALESCE(actual.line_count, 0) <> selected.old_ingredient_count;

DELETE selected FROM distinct_recipe_selected selected
LEFT JOIN (
  SELECT ri.recipe_id, seed.recipe_title, COUNT(*) AS matching_count
  FROM recipe_ingredients ri
  JOIN ingredients ingredient ON ingredient.ingredient_id = ri.ingredient_id
  JOIN measurement_units unit_row ON unit_row.measurement_unit_id = ri.measurement_unit_id
  JOIN distinct_recipe_ingredient seed
    ON seed.phase = 'old'
   AND BINARY seed.ingredient_name = BINARY ingredient.ingredient_name
   AND BINARY seed.unit_symbol = BINARY unit_row.unit_symbol
   AND seed.quantity = ri.quantity AND seed.sort_order = ri.sort_order
   AND seed.preparation_note <=> ri.preparation_note
  GROUP BY ri.recipe_id, seed.recipe_title
) matched ON matched.recipe_id = selected.recipe_id
  AND BINARY matched.recipe_title = BINARY selected.old_title
WHERE COALESCE(matched.matching_count, 0) <> selected.old_ingredient_count;

DELETE selected FROM distinct_recipe_selected selected
LEFT JOIN (
  SELECT seed.recipe_title, COUNT(*) AS available_count
  FROM distinct_recipe_ingredient seed
  JOIN ingredients ingredient ON BINARY ingredient.ingredient_name = BINARY seed.ingredient_name
  JOIN measurement_units unit_row ON BINARY unit_row.unit_symbol = BINARY seed.unit_symbol
  WHERE seed.phase = 'new'
  GROUP BY seed.recipe_title
) available ON BINARY available.recipe_title = BINARY selected.old_title
WHERE COALESCE(available.available_count, 0) <> selected.new_ingredient_count;

DELETE selected FROM distinct_recipe_selected selected
LEFT JOIN (
  SELECT recipe_id, COUNT(*) AS step_count
  FROM recipe_steps GROUP BY recipe_id
) actual ON actual.recipe_id = selected.recipe_id
WHERE COALESCE(actual.step_count, 0) <> selected.old_step_count;

DELETE selected FROM distinct_recipe_selected selected
LEFT JOIN (
  SELECT step_row.recipe_id, seed.recipe_title, COUNT(*) AS matching_count
  FROM recipe_steps step_row
  JOIN distinct_recipe_step seed
    ON seed.phase = 'old' AND seed.step_number = step_row.step_number
   AND BINARY seed.instruction = BINARY step_row.instruction
  GROUP BY step_row.recipe_id, seed.recipe_title
) matched ON matched.recipe_id = selected.recipe_id
  AND BINARY matched.recipe_title = BINARY selected.old_title
WHERE COALESCE(matched.matching_count, 0) <> selected.old_step_count;

UPDATE recipes recipe
JOIN distinct_recipe_selected selected ON selected.recipe_id = recipe.recipe_id
JOIN distinct_recipe_revision revision ON revision.old_title = selected.old_title
JOIN cuisines new_cuisine ON BINARY new_cuisine.cuisine_name = BINARY revision.new_cuisine
SET recipe.title = revision.new_title,
    recipe.description = revision.new_description,
    recipe.image_url = revision.new_image_url,
    recipe.estimated_cost = revision.new_estimated_cost,
    recipe.cuisine_id = new_cuisine.cuisine_id,
    recipe.difficulty = revision.new_difficulty;

DELETE ri FROM recipe_ingredients ri
JOIN distinct_recipe_selected selected ON selected.recipe_id = ri.recipe_id;

INSERT INTO recipe_ingredients (
  recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order, preparation_note
)
SELECT selected.recipe_id, ingredient.ingredient_id, unit_row.measurement_unit_id,
       seed.quantity, seed.sort_order, seed.preparation_note
FROM distinct_recipe_selected selected
JOIN distinct_recipe_ingredient seed
  ON seed.recipe_title = selected.old_title AND seed.phase = 'new'
JOIN ingredients ingredient ON BINARY ingredient.ingredient_name = BINARY seed.ingredient_name
JOIN measurement_units unit_row ON BINARY unit_row.unit_symbol = BINARY seed.unit_symbol;

DELETE step_row FROM recipe_steps step_row
JOIN distinct_recipe_selected selected ON selected.recipe_id = step_row.recipe_id;

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT selected.recipe_id, seed.step_number, seed.instruction
FROM distinct_recipe_selected selected
JOIN distinct_recipe_step seed
  ON seed.recipe_title = selected.old_title AND seed.phase = 'new';

-- Align only the selected revisions with their new ingredients and cooking method.
DELETE tagged FROM recipe_dietary_tags tagged
JOIN distinct_recipe_selected selected ON selected.recipe_id = tagged.recipe_id
JOIN dietary_tags tag ON tag.dietary_tag_id = tagged.dietary_tag_id
WHERE selected.old_title IN ('Garlic Mushroom Rice Skillet', 'Mushroom Lentil Risotto')
  AND tag.tag_name = 'Vegan';

INSERT INTO recipe_dietary_tags (recipe_id, dietary_tag_id)
SELECT selected.recipe_id, tag.dietary_tag_id
FROM distinct_recipe_selected selected
JOIN dietary_tags tag ON tag.tag_name = 'Vegan'
WHERE selected.old_title = 'Garlic Tomato Pasta'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_dietary_tags existing
    WHERE existing.recipe_id = selected.recipe_id AND existing.dietary_tag_id = tag.dietary_tag_id
  );

INSERT INTO recipe_equipment (recipe_id, equipment_id)
SELECT selected.recipe_id, equipment_row.equipment_id
FROM distinct_recipe_selected selected
JOIN equipment equipment_row ON equipment_row.equipment_name = 'Frying pan'
WHERE selected.old_title = 'Mushroom Lentil Risotto'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_equipment existing
    WHERE existing.recipe_id = selected.recipe_id
      AND existing.equipment_id = equipment_row.equipment_id
  );

-- The replacement frittata no longer contains pasta; add the now-accurate diet tag.
-- This also repairs an already-applied revision when the migration is run again.
INSERT INTO recipe_dietary_tags (recipe_id, dietary_tag_id)
SELECT recipe.recipe_id, tag.dietary_tag_id
FROM recipes recipe
JOIN users author ON author.user_id = recipe.author_user_id AND author.email = 'yuki@qq.com'
JOIN dietary_tags tag ON tag.tag_name = 'Gluten-Free'
WHERE BINARY recipe.title = BINARY 'Broccoli Egg Frittata'
  AND BINARY recipe.description = BINARY 'A stovetop broccoli and egg frittata with tender onion and a splash of milk.'
  AND BINARY recipe.image_url = BINARY '/images/recipes/broccoli-egg-frittata-20260930.png'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_ingredients ingredient_row
    JOIN ingredient_allergens link ON link.ingredient_id = ingredient_row.ingredient_id
    JOIN allergies allergy ON allergy.allergy_id = link.allergy_id
    WHERE ingredient_row.recipe_id = recipe.recipe_id
      AND allergy.allergy_name IN ('Gluten', 'Wheat')
  )
  AND NOT EXISTS (
    SELECT 1 FROM recipe_dietary_tags existing
    WHERE existing.recipe_id = recipe.recipe_id AND existing.dietary_tag_id = tag.dietary_tag_id
  );

-- Only exact, unchanged demonstration feedback is revised; all other comments remain.
DROP TEMPORARY TABLE IF EXISTS distinct_recipe_comment;
CREATE TEMPORARY TABLE distinct_recipe_comment (
  recipe_title VARCHAR(160) NOT NULL,
  reviewer_email VARCHAR(255) NOT NULL,
  old_comment TEXT NOT NULL,
  new_comment TEXT NOT NULL,
  PRIMARY KEY (recipe_title, reviewer_email)
) ENGINE=InnoDB;

INSERT INTO distinct_recipe_comment VALUES
  ('Cumin Chickpea Rice Skillet', 'student.michael@unimeal.test',
   'The coconut milk balances the cumin and tomato nicely.',
   'Browning the chickpeas and broccoli with cumin gives the rice a warm, toasty flavour.'),
  ('Tomato Egg Pasta', 'student.alice@unimeal.test',
   'The egg adds extra protein while keeping the tomato pasta simple.',
   'The broccoli and egg make this frittata a filling, easy-to-portion meal.'),
  ('Tomato Egg Pasta', 'student.michael@unimeal.test',
   'Stirring gently after adding the egg gave the sauce a soft texture.',
   'Keeping the pan covered on low heat set the centre without overcooking the edges.'),
  ('Creamy Chicken Mushroom Pasta', 'student.alice@unimeal.test',
   'The mushroom and cream sauce is satisfying and the instructions are clear.',
   'The warm chicken and vegetable filling makes these wraps convenient for lunch.'),
  ('Creamy Chicken Mushroom Pasta', 'student.michael@unimeal.test',
   'Keeping the heat low after adding cream prevented the sauce from splitting.',
   'Cooking off the mushroom liquid kept the wraps from getting soggy.'),
  ('Garlic Mushroom Rice Skillet', 'student.alice@unimeal.test',
   'Cooking the mushrooms until browned gives this simple skillet much more flavour.',
   'Browning the mushrooms gave the soup a deeper flavour without cream.'),
  ('Garlic Mushroom Rice Skillet', 'student.michael@unimeal.test',
   'The steps are easy to follow when the rice is prepared first.',
   'Mashing some mushrooms thickened the soup without needing a blender.'),
  ('Garlic Tomato Pasta', 'student.alice@unimeal.test',
   'The tomato and garlic sauce is quick to make and works well for a low-cost dinner.',
   'The grated carrot adds sweetness to the creamy hummus pasta.'),
  ('Garlic Tomato Pasta', 'student.michael@unimeal.test',
   'Saving a little pasta water made it easier to coat the noodles evenly.',
   'A little pasta water helped the hummus coat every strand.'),
  ('Mushroom Lentil Risotto', 'student.alice@unimeal.test',
   'The gradual stock additions make the longer cooking method easy to understand.',
   'Draining the lentils well helped the patties hold their shape.'),
  ('Mushroom Lentil Risotto', 'student.michael@unimeal.test',
   'The lentils add texture and make the risotto more filling.',
   'Resting the mixture before frying made the patties easier to turn.');

UPDATE recipe_comments comment_row
JOIN distinct_recipe_selected selected ON selected.recipe_id = comment_row.recipe_id
JOIN distinct_recipe_comment seed ON seed.recipe_title = selected.old_title
JOIN users reviewer ON reviewer.user_id = comment_row.user_id
  AND reviewer.email = seed.reviewer_email
SET comment_row.comment_text = seed.new_comment
WHERE BINARY comment_row.comment_text = BINARY seed.old_comment;

DROP TEMPORARY TABLE IF EXISTS distinct_recipe_comment;
DROP TEMPORARY TABLE IF EXISTS distinct_recipe_selected;
DROP TEMPORARY TABLE IF EXISTS distinct_recipe_step;
DROP TEMPORARY TABLE IF EXISTS distinct_recipe_ingredient;
DROP TEMPORARY TABLE IF EXISTS distinct_recipe_revision;
COMMIT;
