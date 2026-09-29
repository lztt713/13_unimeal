-- Add fifteen complete, student-friendly recipes for local UniMeal demonstrations.
-- This migration is idempotent and preserves existing recipes and user data.
USE unimeal_planner;
START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS new_recipe_seed;
CREATE TEMPORARY TABLE new_recipe_seed (
  title VARCHAR(160) NOT NULL PRIMARY KEY,
  cuisine_name VARCHAR(80) NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  description TEXT NOT NULL,
  preparation_minutes SMALLINT UNSIGNED NOT NULL,
  cooking_minutes SMALLINT UNSIGNED NOT NULL,
  servings TINYINT UNSIGNED NOT NULL,
  difficulty ENUM('easy', 'medium', 'hard') NOT NULL,
  estimated_cost DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

INSERT INTO new_recipe_seed (
  title, cuisine_name, image_url, description,
  preparation_minutes, cooking_minutes, servings, difficulty, estimated_cost
) VALUES
  ('Garlic Tomato Pasta', 'Italian', '/images/recipes/garlic-tomato-pasta-20260929.png', 'A low-cost pasta dinner with garlic, tomato and olive oil for a busy student evening.', 7, 13, 2, 'easy', 2.80),
  ('Chickpea Tomato Rice', 'Indian', '/images/recipes/chickpea-tomato-rice-20260929.png', 'A creamy tomato and chickpea rice bowl with warming cumin and coconut milk.', 8, 17, 2, 'easy', 3.10),
  ('Coconut Lentil Soup', 'Indian', '/images/recipes/coconut-lentil-soup-20260929.png', 'A filling lentil soup with coconut milk, vegetables and gentle cumin spice.', 10, 20, 2, 'easy', 3.50),
  ('Hummus Veggie Rice Bowl', 'Mediterranean', '/images/recipes/hummus-veggie-rice-bowl-20260929.png', 'A colourful rice bowl topped with hummus and crisp vegetables.', 10, 10, 2, 'easy', 3.00),
  ('Garlic Mushroom Rice Skillet', 'Chinese', '/images/recipes/garlic-mushroom-rice-skillet-20260929.png', 'A simple mushroom and vegetable rice skillet with garlic and olive oil.', 8, 15, 2, 'easy', 2.70),
  ('Hummus Carrot Crunch Wrap', 'Mediterranean', '/images/recipes/hummus-carrot-crunch-wrap-20260929.png', 'A no-cook wrap with hummus, carrot, cucumber and tomato.', 8, 0, 2, 'easy', 3.70),
  ('Tomato Cumin Lentils', 'Middle Eastern', '/images/recipes/tomato-cumin-lentils-20260929.png', 'Tomato braised lentils with cumin, garlic and a rich vegetable stock.', 8, 22, 2, 'easy', 3.10),
  ('Broccoli Chickpea Pasta', 'European', '/images/recipes/broccoli-chickpea-pasta-20260929.png', 'A quick pasta meal combining broccoli, chickpeas and garlic.', 10, 16, 2, 'medium', 2.90),
  ('Chicken Garlic Rice Bowl', 'Chinese', '/images/recipes/chicken-garlic-rice-bowl-20260929.png', 'A high-protein chicken, broccoli and garlic rice bowl.', 10, 18, 2, 'medium', 4.10),
  ('Chicken Tomato Pasta', 'Italian', '/images/recipes/chicken-tomato-pasta-20260929.png', 'A weeknight chicken pasta with a fresh tomato and garlic sauce.', 8, 19, 2, 'medium', 4.70),
  ('Creamy Chicken Mushroom Pasta', 'European', '/images/recipes/creamy-chicken-mushroom-pasta-20260929.png', 'Creamy chicken and mushroom pasta for a satisfying high-protein dinner.', 10, 23, 2, 'medium', 4.95),
  ('Broccoli Egg Fried Rice', 'Chinese', '/images/recipes/broccoli-egg-fried-rice-20260929.png', 'Egg fried rice with broccoli, carrot and garlic.', 8, 15, 2, 'medium', 3.70),
  ('Mushroom Lentil Risotto', 'Italian', '/images/recipes/mushroom-lentil-risotto-20260929.png', 'A slow-cooked mushroom and lentil risotto with vegetable stock.', 10, 28, 2, 'hard', 3.82),
  ('Tomato Egg Pasta', 'European', '/images/recipes/tomato-egg-pasta-20260929.png', 'Tomato pasta finished with softly cooked egg for extra protein.', 7, 14, 2, 'medium', 4.05),
  ('Cumin Chickpea Rice Skillet', 'Indian', '/images/recipes/cumin-chickpea-rice-skillet-20260929.png', 'A one-pan chickpea rice skillet with tomato, cumin and coconut milk.', 10, 17, 2, 'easy', 3.16);

-- All new recipes are submitted by the existing contributor account created for demos.
INSERT INTO recipes (
  author_user_id, cuisine_id, title, image_url, description,
  preparation_minutes, cooking_minutes, servings, difficulty, estimated_cost, status
)
SELECT author.user_id, cuisine.cuisine_id, seed.title, seed.image_url, seed.description,
       seed.preparation_minutes, seed.cooking_minutes, seed.servings,
       seed.difficulty, seed.estimated_cost, 'published'
FROM new_recipe_seed seed
JOIN users author ON author.email = 'yuki@qq.com'
JOIN roles role_row ON role_row.role_id = author.role_id AND role_row.role_name = 'contributor'
JOIN cuisines cuisine ON cuisine.cuisine_name = seed.cuisine_name
WHERE NOT EXISTS (SELECT 1 FROM recipes existing WHERE existing.title = seed.title);

DROP TEMPORARY TABLE IF EXISTS new_recipe_ingredient_seed;
CREATE TEMPORARY TABLE new_recipe_ingredient_seed (
  recipe_title VARCHAR(160) NOT NULL,
  ingredient_name VARCHAR(120) NOT NULL,
  unit_symbol VARCHAR(12) NOT NULL,
  quantity DECIMAL(10,3) NOT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL,
  preparation_note VARCHAR(160) NULL,
  PRIMARY KEY (recipe_title, sort_order)
) ENGINE=InnoDB;

INSERT INTO new_recipe_ingredient_seed (
  recipe_title, ingredient_name, unit_symbol, quantity, sort_order, preparation_note
) VALUES
  ('Garlic Tomato Pasta', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Garlic Tomato Pasta', 'Tomato', 'pc', 3.000, 2, 'chopped'),
  ('Garlic Tomato Pasta', 'Garlic', 'pc', 2.000, 3, 'minced'),
  ('Garlic Tomato Pasta', 'Onion', 'pc', 1.000, 4, 'diced'),
  ('Garlic Tomato Pasta', 'Olive Oil', 'ml', 10.000, 5, NULL),

  ('Chickpea Tomato Rice', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Chickpea Tomato Rice', 'Chickpeas', 'g', 240.000, 2, 'cooked and drained'),
  ('Chickpea Tomato Rice', 'Tomato', 'pc', 2.000, 3, 'chopped'),
  ('Chickpea Tomato Rice', 'Onion', 'pc', 1.000, 4, 'diced'),
  ('Chickpea Tomato Rice', 'Garlic', 'pc', 2.000, 5, 'minced'),
  ('Chickpea Tomato Rice', 'Cumin', 'tsp', 1.000, 6, NULL),
  ('Chickpea Tomato Rice', 'Coconut Milk', 'ml', 100.000, 7, NULL),

  ('Coconut Lentil Soup', 'Lentils', 'g', 180.000, 1, 'rinsed'),
  ('Coconut Lentil Soup', 'Coconut Milk', 'ml', 150.000, 2, NULL),
  ('Coconut Lentil Soup', 'Carrot', 'pc', 2.000, 3, 'diced'),
  ('Coconut Lentil Soup', 'Onion', 'pc', 1.000, 4, 'diced'),
  ('Coconut Lentil Soup', 'Garlic', 'pc', 2.000, 5, 'minced'),
  ('Coconut Lentil Soup', 'Cumin', 'tsp', 1.000, 6, NULL),
  ('Coconut Lentil Soup', 'Vegetable Stock', 'ml', 700.000, 7, NULL),

  ('Hummus Veggie Rice Bowl', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Hummus Veggie Rice Bowl', 'Hummus', 'g', 120.000, 2, NULL),
  ('Hummus Veggie Rice Bowl', 'Cucumber', 'pc', 1.000, 3, 'diced'),
  ('Hummus Veggie Rice Bowl', 'Tomato', 'pc', 2.000, 4, 'diced'),
  ('Hummus Veggie Rice Bowl', 'Carrot', 'pc', 1.000, 5, 'grated'),
  ('Hummus Veggie Rice Bowl', 'Olive Oil', 'ml', 10.000, 6, NULL),

  ('Garlic Mushroom Rice Skillet', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Garlic Mushroom Rice Skillet', 'Mushrooms', 'g', 200.000, 2, 'sliced'),
  ('Garlic Mushroom Rice Skillet', 'Garlic', 'pc', 2.000, 3, 'minced'),
  ('Garlic Mushroom Rice Skillet', 'Onion', 'pc', 1.000, 4, 'diced'),
  ('Garlic Mushroom Rice Skillet', 'Carrot', 'pc', 1.000, 5, 'thinly sliced'),
  ('Garlic Mushroom Rice Skillet', 'Olive Oil', 'ml', 10.000, 6, NULL),

  ('Hummus Carrot Crunch Wrap', 'Wrap', 'pc', 2.000, 1, NULL),
  ('Hummus Carrot Crunch Wrap', 'Hummus', 'g', 120.000, 2, NULL),
  ('Hummus Carrot Crunch Wrap', 'Carrot', 'pc', 2.000, 3, 'grated'),
  ('Hummus Carrot Crunch Wrap', 'Cucumber', 'pc', 1.000, 4, 'thinly sliced'),
  ('Hummus Carrot Crunch Wrap', 'Tomato', 'pc', 1.000, 5, 'sliced'),
  ('Hummus Carrot Crunch Wrap', 'Olive Oil', 'ml', 5.000, 6, NULL),

  ('Tomato Cumin Lentils', 'Lentils', 'g', 180.000, 1, 'rinsed'),
  ('Tomato Cumin Lentils', 'Tomato', 'pc', 3.000, 2, 'chopped'),
  ('Tomato Cumin Lentils', 'Onion', 'pc', 1.000, 3, 'diced'),
  ('Tomato Cumin Lentils', 'Garlic', 'pc', 2.000, 4, 'minced'),
  ('Tomato Cumin Lentils', 'Cumin', 'tsp', 1.000, 5, NULL),
  ('Tomato Cumin Lentils', 'Vegetable Stock', 'ml', 600.000, 6, NULL),
  ('Tomato Cumin Lentils', 'Olive Oil', 'ml', 10.000, 7, NULL),

  ('Broccoli Chickpea Pasta', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Broccoli Chickpea Pasta', 'Broccoli', 'g', 200.000, 2, 'small florets'),
  ('Broccoli Chickpea Pasta', 'Chickpeas', 'g', 240.000, 3, 'cooked and drained'),
  ('Broccoli Chickpea Pasta', 'Garlic', 'pc', 2.000, 4, 'minced'),
  ('Broccoli Chickpea Pasta', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Broccoli Chickpea Pasta', 'Olive Oil', 'ml', 10.000, 6, NULL),

  ('Chicken Garlic Rice Bowl', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Chicken Garlic Rice Bowl', 'Chicken', 'g', 250.000, 2, 'bite-size pieces'),
  ('Chicken Garlic Rice Bowl', 'Broccoli', 'g', 200.000, 3, 'small florets'),
  ('Chicken Garlic Rice Bowl', 'Garlic', 'pc', 2.000, 4, 'minced'),
  ('Chicken Garlic Rice Bowl', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Chicken Garlic Rice Bowl', 'Olive Oil', 'ml', 10.000, 6, NULL),

  ('Chicken Tomato Pasta', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Chicken Tomato Pasta', 'Chicken', 'g', 250.000, 2, 'bite-size pieces'),
  ('Chicken Tomato Pasta', 'Tomato', 'pc', 3.000, 3, 'chopped'),
  ('Chicken Tomato Pasta', 'Garlic', 'pc', 2.000, 4, 'minced'),
  ('Chicken Tomato Pasta', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Chicken Tomato Pasta', 'Olive Oil', 'ml', 10.000, 6, NULL),

  ('Creamy Chicken Mushroom Pasta', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Creamy Chicken Mushroom Pasta', 'Chicken', 'g', 250.000, 2, 'bite-size pieces'),
  ('Creamy Chicken Mushroom Pasta', 'Mushrooms', 'g', 200.000, 3, 'sliced'),
  ('Creamy Chicken Mushroom Pasta', 'Cream', 'ml', 120.000, 4, NULL),
  ('Creamy Chicken Mushroom Pasta', 'Milk', 'ml', 100.000, 5, NULL),
  ('Creamy Chicken Mushroom Pasta', 'Garlic', 'pc', 2.000, 6, 'minced'),
  ('Creamy Chicken Mushroom Pasta', 'Olive Oil', 'ml', 10.000, 7, NULL),

  ('Broccoli Egg Fried Rice', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Broccoli Egg Fried Rice', 'Egg', 'pc', 4.000, 2, 'beaten'),
  ('Broccoli Egg Fried Rice', 'Broccoli', 'g', 200.000, 3, 'small florets'),
  ('Broccoli Egg Fried Rice', 'Carrot', 'pc', 1.000, 4, 'small dice'),
  ('Broccoli Egg Fried Rice', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Broccoli Egg Fried Rice', 'Garlic', 'pc', 2.000, 6, 'minced'),
  ('Broccoli Egg Fried Rice', 'Olive Oil', 'ml', 10.000, 7, NULL),

  ('Mushroom Lentil Risotto', 'Risotto Rice', 'g', 180.000, 1, NULL),
  ('Mushroom Lentil Risotto', 'Lentils', 'g', 120.000, 2, 'rinsed'),
  ('Mushroom Lentil Risotto', 'Mushrooms', 'g', 200.000, 3, 'sliced'),
  ('Mushroom Lentil Risotto', 'Vegetable Stock', 'ml', 700.000, 4, 'kept warm'),
  ('Mushroom Lentil Risotto', 'Onion', 'pc', 1.000, 5, 'finely diced'),
  ('Mushroom Lentil Risotto', 'Garlic', 'pc', 2.000, 6, 'minced'),
  ('Mushroom Lentil Risotto', 'Olive Oil', 'ml', 10.000, 7, NULL),

  ('Tomato Egg Pasta', 'Pasta', 'g', 180.000, 1, 'dry'),
  ('Tomato Egg Pasta', 'Egg', 'pc', 4.000, 2, 'beaten'),
  ('Tomato Egg Pasta', 'Tomato', 'pc', 3.000, 3, 'chopped'),
  ('Tomato Egg Pasta', 'Garlic', 'pc', 2.000, 4, 'minced'),
  ('Tomato Egg Pasta', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Tomato Egg Pasta', 'Olive Oil', 'ml', 10.000, 6, NULL),

  ('Cumin Chickpea Rice Skillet', 'Rice', 'g', 160.000, 1, 'dry'),
  ('Cumin Chickpea Rice Skillet', 'Chickpeas', 'g', 240.000, 2, 'cooked and drained'),
  ('Cumin Chickpea Rice Skillet', 'Coconut Milk', 'ml', 120.000, 3, NULL),
  ('Cumin Chickpea Rice Skillet', 'Tomato', 'pc', 2.000, 4, 'chopped'),
  ('Cumin Chickpea Rice Skillet', 'Onion', 'pc', 1.000, 5, 'diced'),
  ('Cumin Chickpea Rice Skillet', 'Garlic', 'pc', 2.000, 6, 'minced'),
  ('Cumin Chickpea Rice Skillet', 'Cumin', 'tsp', 1.000, 7, NULL),
  ('Cumin Chickpea Rice Skillet', 'Olive Oil', 'ml', 10.000, 8, NULL);

INSERT INTO recipe_ingredients (
  recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order, preparation_note
)
SELECT recipe.recipe_id, ingredient.ingredient_id, unit_row.measurement_unit_id,
       seed.quantity, seed.sort_order, seed.preparation_note
FROM new_recipe_ingredient_seed seed
JOIN recipes recipe ON recipe.title = seed.recipe_title
JOIN ingredients ingredient ON ingredient.ingredient_name = seed.ingredient_name
JOIN measurement_units unit_row ON unit_row.unit_symbol = seed.unit_symbol
WHERE NOT EXISTS (
  SELECT 1 FROM recipe_ingredients existing
  WHERE existing.recipe_id = recipe.recipe_id
    AND existing.ingredient_id = ingredient.ingredient_id
    AND existing.measurement_unit_id = unit_row.measurement_unit_id
    AND existing.sort_order = seed.sort_order
);

DROP TEMPORARY TABLE IF EXISTS new_recipe_step_seed;
CREATE TEMPORARY TABLE new_recipe_step_seed (
  recipe_title VARCHAR(160) NOT NULL,
  step_number SMALLINT UNSIGNED NOT NULL,
  instruction TEXT NOT NULL,
  PRIMARY KEY (recipe_title, step_number)
) ENGINE=InnoDB;

INSERT INTO new_recipe_step_seed (recipe_title, step_number, instruction) VALUES
  ('Garlic Tomato Pasta', 1, 'Boil the pasta in water until just tender, then reserve a little cooking water.'),
  ('Garlic Tomato Pasta', 2, 'Warm olive oil in a frying pan and cook the onion and garlic until softened.'),
  ('Garlic Tomato Pasta', 3, 'Add the chopped tomatoes and simmer until they make a quick sauce.'),
  ('Garlic Tomato Pasta', 4, 'Toss the pasta through the sauce, loosening with reserved water if needed.'),

  ('Chickpea Tomato Rice', 1, 'Cook the rice in a saucepan until tender.'),
  ('Chickpea Tomato Rice', 2, 'Cook onion, garlic and cumin in a frying pan with a small amount of oil.'),
  ('Chickpea Tomato Rice', 3, 'Add tomato, chickpeas and coconut milk, then simmer for eight minutes.'),
  ('Chickpea Tomato Rice', 4, 'Spoon the chickpea mixture over the cooked rice and serve.'),

  ('Coconut Lentil Soup', 1, 'Cook the onion, carrot, garlic and cumin in a saucepan until fragrant.'),
  ('Coconut Lentil Soup', 2, 'Add lentils and vegetable stock, then bring the soup to a gentle boil.'),
  ('Coconut Lentil Soup', 3, 'Simmer until the lentils are tender and the vegetables are soft.'),
  ('Coconut Lentil Soup', 4, 'Stir in coconut milk, heat through and serve.'),

  ('Hummus Veggie Rice Bowl', 1, 'Cook the rice in a saucepan and let it steam for a few minutes.'),
  ('Hummus Veggie Rice Bowl', 2, 'Prepare the cucumber, tomato and carrot while the rice cooks.'),
  ('Hummus Veggie Rice Bowl', 3, 'Divide the warm rice between bowls and add hummus.'),
  ('Hummus Veggie Rice Bowl', 4, 'Top with the vegetables, drizzle with olive oil and serve.'),

  ('Garlic Mushroom Rice Skillet', 1, 'Cook the rice in a saucepan until tender.'),
  ('Garlic Mushroom Rice Skillet', 2, 'Cook onion, carrot, mushrooms and garlic in olive oil in a frying pan.'),
  ('Garlic Mushroom Rice Skillet', 3, 'Continue cooking until the mushrooms are browned and the vegetables are soft.'),
  ('Garlic Mushroom Rice Skillet', 4, 'Fold in the rice, warm through and serve.'),

  ('Hummus Carrot Crunch Wrap', 1, 'Spread hummus evenly over each wrap.'),
  ('Hummus Carrot Crunch Wrap', 2, 'Layer grated carrot, cucumber and tomato down the middle.'),
  ('Hummus Carrot Crunch Wrap', 3, 'Drizzle with olive oil, roll tightly and cut each wrap in half.'),

  ('Tomato Cumin Lentils', 1, 'Cook onion, garlic and cumin in olive oil in a saucepan.'),
  ('Tomato Cumin Lentils', 2, 'Add the tomato, lentils and vegetable stock.'),
  ('Tomato Cumin Lentils', 3, 'Simmer until the lentils are tender and the sauce is thick.'),
  ('Tomato Cumin Lentils', 4, 'Taste, adjust seasoning if needed and serve warm.'),

  ('Broccoli Chickpea Pasta', 1, 'Cook the pasta in a saucepan and add broccoli for the final three minutes.'),
  ('Broccoli Chickpea Pasta', 2, 'Cook onion and garlic in olive oil in a frying pan until soft.'),
  ('Broccoli Chickpea Pasta', 3, 'Add the drained chickpeas and warm them through.'),
  ('Broccoli Chickpea Pasta', 4, 'Toss in the pasta and broccoli, then serve.'),

  ('Chicken Garlic Rice Bowl', 1, 'Cook the rice in a saucepan until tender.'),
  ('Chicken Garlic Rice Bowl', 2, 'Cook chicken in olive oil in a frying pan until browned and fully cooked.'),
  ('Chicken Garlic Rice Bowl', 3, 'Add onion, garlic and broccoli, then cook until the broccoli is tender.'),
  ('Chicken Garlic Rice Bowl', 4, 'Serve the chicken and vegetables over the rice.'),

  ('Chicken Tomato Pasta', 1, 'Cook the pasta in a saucepan until tender.'),
  ('Chicken Tomato Pasta', 2, 'Cook chicken in olive oil in a frying pan until fully cooked.'),
  ('Chicken Tomato Pasta', 3, 'Add onion, garlic and tomato, then simmer into a light sauce.'),
  ('Chicken Tomato Pasta', 4, 'Toss the pasta with the chicken tomato sauce and serve.'),

  ('Creamy Chicken Mushroom Pasta', 1, 'Cook the pasta in a saucepan until tender.'),
  ('Creamy Chicken Mushroom Pasta', 2, 'Cook chicken, mushrooms and garlic in olive oil until the chicken is fully cooked.'),
  ('Creamy Chicken Mushroom Pasta', 3, 'Add milk and cream, then simmer briefly until lightly thickened.'),
  ('Creamy Chicken Mushroom Pasta', 4, 'Toss the pasta through the sauce and serve immediately.'),

  ('Broccoli Egg Fried Rice', 1, 'Cook the rice in a saucepan, or use cooled leftover rice.'),
  ('Broccoli Egg Fried Rice', 2, 'Cook broccoli, carrot, onion and garlic in olive oil in a frying pan.'),
  ('Broccoli Egg Fried Rice', 3, 'Push the vegetables aside and scramble the beaten egg in the same pan.'),
  ('Broccoli Egg Fried Rice', 4, 'Fold in the rice, stir until hot and serve.'),

  ('Mushroom Lentil Risotto', 1, 'Cook onion, garlic and mushrooms in olive oil in a saucepan until softened.'),
  ('Mushroom Lentil Risotto', 2, 'Add risotto rice and stir for one minute to coat it in the oil.'),
  ('Mushroom Lentil Risotto', 3, 'Add warm stock gradually, stirring after each addition is absorbed.'),
  ('Mushroom Lentil Risotto', 4, 'Add lentils halfway through and continue cooking until the rice is creamy and tender.'),
  ('Mushroom Lentil Risotto', 5, 'Rest for two minutes before serving.'),

  ('Tomato Egg Pasta', 1, 'Cook the pasta in a saucepan until tender.'),
  ('Tomato Egg Pasta', 2, 'Cook onion and garlic in olive oil in a frying pan until soft.'),
  ('Tomato Egg Pasta', 3, 'Add tomato and simmer until it forms a quick sauce.'),
  ('Tomato Egg Pasta', 4, 'Stir in beaten egg and pasta, cooking gently until the egg is set.'),

  ('Cumin Chickpea Rice Skillet', 1, 'Cook the rice in a saucepan until tender.'),
  ('Cumin Chickpea Rice Skillet', 2, 'Cook onion, garlic and cumin in olive oil in a frying pan.'),
  ('Cumin Chickpea Rice Skillet', 3, 'Add tomato, chickpeas and coconut milk, then simmer until thickened.'),
  ('Cumin Chickpea Rice Skillet', 4, 'Fold in the rice, heat through and serve.' );

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT recipe.recipe_id, seed.step_number, seed.instruction
FROM new_recipe_step_seed seed
JOIN recipes recipe ON recipe.title = seed.recipe_title
WHERE NOT EXISTS (
  SELECT 1 FROM recipe_steps existing
  WHERE existing.recipe_id = recipe.recipe_id AND existing.step_number = seed.step_number
);

DROP TEMPORARY TABLE IF EXISTS new_recipe_tag_seed;
CREATE TEMPORARY TABLE new_recipe_tag_seed (
  recipe_title VARCHAR(160) NOT NULL,
  tag_name VARCHAR(60) NOT NULL,
  PRIMARY KEY (recipe_title, tag_name)
) ENGINE=Memory;

INSERT INTO new_recipe_tag_seed (recipe_title, tag_name) VALUES
  ('Garlic Tomato Pasta', 'Vegetarian'), ('Garlic Tomato Pasta', 'Budget'),
  ('Chickpea Tomato Rice', 'Vegan'), ('Chickpea Tomato Rice', 'Vegetarian'), ('Chickpea Tomato Rice', 'Budget'), ('Chickpea Tomato Rice', 'Gluten-Free'),
  ('Coconut Lentil Soup', 'Vegan'), ('Coconut Lentil Soup', 'Vegetarian'), ('Coconut Lentil Soup', 'High Protein'), ('Coconut Lentil Soup', 'Budget'), ('Coconut Lentil Soup', 'Gluten-Free'),
  ('Hummus Veggie Rice Bowl', 'Vegan'), ('Hummus Veggie Rice Bowl', 'Vegetarian'), ('Hummus Veggie Rice Bowl', 'Budget'), ('Hummus Veggie Rice Bowl', 'Gluten-Free'),
  ('Garlic Mushroom Rice Skillet', 'Vegan'), ('Garlic Mushroom Rice Skillet', 'Vegetarian'), ('Garlic Mushroom Rice Skillet', 'Budget'), ('Garlic Mushroom Rice Skillet', 'Gluten-Free'),
  ('Hummus Carrot Crunch Wrap', 'Vegan'), ('Hummus Carrot Crunch Wrap', 'Vegetarian'), ('Hummus Carrot Crunch Wrap', 'Budget'),
  ('Tomato Cumin Lentils', 'Vegan'), ('Tomato Cumin Lentils', 'Vegetarian'), ('Tomato Cumin Lentils', 'High Protein'), ('Tomato Cumin Lentils', 'Budget'), ('Tomato Cumin Lentils', 'Gluten-Free'),
  ('Broccoli Chickpea Pasta', 'Vegan'), ('Broccoli Chickpea Pasta', 'Vegetarian'), ('Broccoli Chickpea Pasta', 'High Protein'), ('Broccoli Chickpea Pasta', 'Budget'),
  ('Chicken Garlic Rice Bowl', 'High Protein'), ('Chicken Garlic Rice Bowl', 'Budget'), ('Chicken Garlic Rice Bowl', 'Gluten-Free'),
  ('Chicken Tomato Pasta', 'High Protein'), ('Chicken Tomato Pasta', 'Budget'),
  ('Creamy Chicken Mushroom Pasta', 'High Protein'), ('Creamy Chicken Mushroom Pasta', 'Budget'),
  ('Broccoli Egg Fried Rice', 'Vegetarian'), ('Broccoli Egg Fried Rice', 'High Protein'), ('Broccoli Egg Fried Rice', 'Budget'), ('Broccoli Egg Fried Rice', 'Gluten-Free'),
  ('Mushroom Lentil Risotto', 'Vegan'), ('Mushroom Lentil Risotto', 'Vegetarian'), ('Mushroom Lentil Risotto', 'High Protein'), ('Mushroom Lentil Risotto', 'Budget'), ('Mushroom Lentil Risotto', 'Gluten-Free'),
  ('Tomato Egg Pasta', 'Vegetarian'), ('Tomato Egg Pasta', 'High Protein'), ('Tomato Egg Pasta', 'Budget'),
  ('Cumin Chickpea Rice Skillet', 'Vegan'), ('Cumin Chickpea Rice Skillet', 'Vegetarian'), ('Cumin Chickpea Rice Skillet', 'High Protein'), ('Cumin Chickpea Rice Skillet', 'Budget'), ('Cumin Chickpea Rice Skillet', 'Gluten-Free');

INSERT INTO recipe_dietary_tags (recipe_id, dietary_tag_id)
SELECT recipe.recipe_id, tag_row.dietary_tag_id
FROM new_recipe_tag_seed seed
JOIN recipes recipe ON recipe.title = seed.recipe_title
JOIN dietary_tags tag_row ON tag_row.tag_name = seed.tag_name
WHERE NOT EXISTS (
  SELECT 1 FROM recipe_dietary_tags existing
  WHERE existing.recipe_id = recipe.recipe_id AND existing.dietary_tag_id = tag_row.dietary_tag_id
);

DROP TEMPORARY TABLE IF EXISTS new_recipe_equipment_seed;
CREATE TEMPORARY TABLE new_recipe_equipment_seed (
  recipe_title VARCHAR(160) NOT NULL,
  equipment_name VARCHAR(80) NOT NULL,
  PRIMARY KEY (recipe_title, equipment_name)
) ENGINE=Memory;

INSERT INTO new_recipe_equipment_seed (recipe_title, equipment_name) VALUES
  ('Garlic Tomato Pasta', 'Hob'), ('Garlic Tomato Pasta', 'Saucepan'), ('Garlic Tomato Pasta', 'Frying pan'),
  ('Chickpea Tomato Rice', 'Hob'), ('Chickpea Tomato Rice', 'Saucepan'), ('Chickpea Tomato Rice', 'Frying pan'),
  ('Coconut Lentil Soup', 'Hob'), ('Coconut Lentil Soup', 'Saucepan'),
  ('Hummus Veggie Rice Bowl', 'Hob'), ('Hummus Veggie Rice Bowl', 'Saucepan'),
  ('Garlic Mushroom Rice Skillet', 'Hob'), ('Garlic Mushroom Rice Skillet', 'Saucepan'), ('Garlic Mushroom Rice Skillet', 'Frying pan'),
  ('Tomato Cumin Lentils', 'Hob'), ('Tomato Cumin Lentils', 'Saucepan'),
  ('Broccoli Chickpea Pasta', 'Hob'), ('Broccoli Chickpea Pasta', 'Saucepan'), ('Broccoli Chickpea Pasta', 'Frying pan'),
  ('Chicken Garlic Rice Bowl', 'Hob'), ('Chicken Garlic Rice Bowl', 'Saucepan'), ('Chicken Garlic Rice Bowl', 'Frying pan'),
  ('Chicken Tomato Pasta', 'Hob'), ('Chicken Tomato Pasta', 'Saucepan'), ('Chicken Tomato Pasta', 'Frying pan'),
  ('Creamy Chicken Mushroom Pasta', 'Hob'), ('Creamy Chicken Mushroom Pasta', 'Saucepan'), ('Creamy Chicken Mushroom Pasta', 'Frying pan'),
  ('Broccoli Egg Fried Rice', 'Hob'), ('Broccoli Egg Fried Rice', 'Saucepan'), ('Broccoli Egg Fried Rice', 'Frying pan'),
  ('Mushroom Lentil Risotto', 'Hob'), ('Mushroom Lentil Risotto', 'Saucepan'),
  ('Tomato Egg Pasta', 'Hob'), ('Tomato Egg Pasta', 'Saucepan'), ('Tomato Egg Pasta', 'Frying pan'),
  ('Cumin Chickpea Rice Skillet', 'Hob'), ('Cumin Chickpea Rice Skillet', 'Saucepan'), ('Cumin Chickpea Rice Skillet', 'Frying pan');

INSERT INTO recipe_equipment (recipe_id, equipment_id)
SELECT recipe.recipe_id, equipment_row.equipment_id
FROM new_recipe_equipment_seed seed
JOIN recipes recipe ON recipe.title = seed.recipe_title
JOIN equipment equipment_row ON equipment_row.equipment_name = seed.equipment_name
WHERE NOT EXISTS (
  SELECT 1 FROM recipe_equipment existing
  WHERE existing.recipe_id = recipe.recipe_id AND existing.equipment_id = equipment_row.equipment_id
);

-- Two student ratings per recipe make the new cards immediately useful in the UI.
INSERT INTO recipe_ratings (user_id, recipe_id, rating)
SELECT student.user_id, recipe.recipe_id,
       CASE WHEN student.email = 'student.alice@unimeal.test' THEN 5 ELSE 4 END
FROM new_recipe_seed seed
JOIN recipes recipe ON recipe.title = seed.title
JOIN users student ON student.email IN ('student.alice@unimeal.test', 'student.michael@unimeal.test')
ON DUPLICATE KEY UPDATE rating = VALUES(rating);

DROP TEMPORARY TABLE IF EXISTS new_recipe_equipment_seed;
DROP TEMPORARY TABLE IF EXISTS new_recipe_tag_seed;
DROP TEMPORARY TABLE IF EXISTS new_recipe_step_seed;
DROP TEMPORARY TABLE IF EXISTS new_recipe_ingredient_seed;
DROP TEMPORARY TABLE IF EXISTS new_recipe_seed;
COMMIT;
