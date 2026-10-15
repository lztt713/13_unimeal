-- UniMeal Planner development seed data
-- Run after database/master_schema.sql on a non-production database.

USE unimeal_planner;
START TRANSACTION;

INSERT INTO cuisines (cuisine_name) VALUES
  ('Chinese'),
  ('Italian'),
  ('New Zealand')
ON DUPLICATE KEY UPDATE cuisine_name = VALUES(cuisine_name);

INSERT INTO dietary_tags (tag_name, description) VALUES
  ('Vegetarian', 'No meat or fish'),
  ('Vegan', 'No animal-derived ingredients'),
  ('Gluten-Free', 'Prepared without gluten-containing ingredients')
ON DUPLICATE KEY UPDATE description = VALUES(description);

INSERT INTO allergies (allergy_name) VALUES
  ('Dairy'),
  ('Egg'),
  ('Peanut')
ON DUPLICATE KEY UPDATE allergy_name = VALUES(allergy_name);

INSERT INTO ingredient_categories (category_name) VALUES
  ('Grains'),
  ('Produce'),
  ('Dairy'),
  ('Protein'),
  ('Pantry')
ON DUPLICATE KEY UPDATE category_name = VALUES(category_name);

INSERT INTO users (
  role_id, email, password_hash, display_name, cooking_skill, kitchen_access, favourite_cuisines_note
)
SELECT role_id, 'student.alice@unimeal.test',
  '$2b$12$z55vKHzHo6z7Twi9krFDb.Wwwm5e8j36GOwlnFvGCpcjiIMkZUFW6',
  'Alice Student', 'beginner', 'shared', 'Chinese, Italian'
FROM roles
WHERE role_name = 'student'
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  cooking_skill = VALUES(cooking_skill),
  kitchen_access = VALUES(kitchen_access),
  favourite_cuisines_note = VALUES(favourite_cuisines_note);

INSERT INTO users (
  role_id, email, password_hash, display_name, cooking_skill, kitchen_access, favourite_cuisines_note
)
SELECT role_id, 'contributor.ben@unimeal.test',
  '$2b$12$yxZBPbcFfhxixwJ1E5mKQeGYgshMPHuvbJ8yvq1xmsH0SowRDhmzW',
  'Ben Contributor', 'advanced', 'full', 'Chinese'
FROM roles
WHERE role_name = 'contributor'
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  cooking_skill = VALUES(cooking_skill),
  kitchen_access = VALUES(kitchen_access),
  favourite_cuisines_note = VALUES(favourite_cuisines_note);

INSERT INTO users (
  role_id, email, password_hash, display_name, cooking_skill, kitchen_access
)
SELECT role_id, 'admin@unimeal.test',
  '$2b$12$T9hjocV3mVwUQ2qOLhNDV.1UiQhILkmeZWhwKybXV2zlDg9oxPA8y',
  'UniMeal Administrator', 'intermediate', 'full'
FROM roles
WHERE role_name = 'administrator'
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  cooking_skill = VALUES(cooking_skill),
  kitchen_access = VALUES(kitchen_access);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id, estimated_unit_cost)
SELECT c.ingredient_category_id, 'Rice', u.measurement_unit_id, 0.0020
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'g'
WHERE c.category_name = 'Grains'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id),
  estimated_unit_cost = VALUES(estimated_unit_cost);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id, estimated_unit_cost)
SELECT c.ingredient_category_id, 'Tomato', u.measurement_unit_id, 0.5000
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE c.category_name = 'Produce'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id),
  estimated_unit_cost = VALUES(estimated_unit_cost);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id, estimated_unit_cost)
SELECT c.ingredient_category_id, 'Onion', u.measurement_unit_id, 0.4000
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE c.category_name = 'Produce'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id),
  estimated_unit_cost = VALUES(estimated_unit_cost);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id, estimated_unit_cost)
SELECT c.ingredient_category_id, 'Egg', u.measurement_unit_id, 0.4500
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE c.category_name = 'Protein'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id),
  estimated_unit_cost = VALUES(estimated_unit_cost);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id, estimated_unit_cost)
SELECT c.ingredient_category_id, 'Milk', u.measurement_unit_id, 0.0020
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'ml'
WHERE c.category_name = 'Dairy'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id),
  estimated_unit_cost = VALUES(estimated_unit_cost);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id, estimated_unit_cost)
SELECT c.ingredient_category_id, 'Bread', u.measurement_unit_id, 0.2500
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE c.category_name = 'Grains'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id),
  estimated_unit_cost = VALUES(estimated_unit_cost);

INSERT INTO ingredient_allergens (ingredient_id, allergy_id)
SELECT i.ingredient_id, a.allergy_id
FROM ingredients i
JOIN allergies a ON a.allergy_name = 'Dairy'
WHERE i.ingredient_name = 'Milk'
  AND NOT EXISTS (
    SELECT 1 FROM ingredient_allergens ia
    WHERE ia.ingredient_id = i.ingredient_id AND ia.allergy_id = a.allergy_id
  );

INSERT INTO user_dietary_preferences (user_id, dietary_tag_id)
SELECT u.user_id, d.dietary_tag_id
FROM users u
JOIN dietary_tags d ON d.tag_name = 'Vegetarian'
WHERE u.email = 'student.alice@unimeal.test'
  AND NOT EXISTS (
    SELECT 1 FROM user_dietary_preferences udp
    WHERE udp.user_id = u.user_id AND udp.dietary_tag_id = d.dietary_tag_id
  );

INSERT INTO recipes (
  author_user_id, cuisine_id, title, description, preparation_minutes, cooking_minutes,
  servings, difficulty, estimated_cost, status
)
SELECT u.user_id, c.cuisine_id, 'Tomato Rice Bowl',
  'A low-cost vegetarian rice bowl for a busy student.', 10, 20, 2, 'easy', 4.50, 'published'
FROM users u
JOIN cuisines c ON c.cuisine_name = 'Chinese'
WHERE u.email = 'contributor.ben@unimeal.test'
  AND NOT EXISTS (SELECT 1 FROM recipes r WHERE r.title = 'Tomato Rice Bowl');

INSERT INTO recipes (
  author_user_id, cuisine_id, title, description, preparation_minutes, cooking_minutes,
  servings, difficulty, estimated_cost, status
)
SELECT u.user_id, c.cuisine_id, 'Egg on Toast',
  'A simple breakfast recipe with egg, milk and bread.', 5, 10, 1, 'easy', 2.80, 'published'
FROM users u
JOIN cuisines c ON c.cuisine_name = 'New Zealand'
WHERE u.email = 'contributor.ben@unimeal.test'
  AND NOT EXISTS (SELECT 1 FROM recipes r WHERE r.title = 'Egg on Toast');

INSERT INTO recipe_dietary_tags (recipe_id, dietary_tag_id)
SELECT r.recipe_id, d.dietary_tag_id
FROM recipes r
JOIN dietary_tags d ON d.tag_name = 'Vegetarian'
WHERE r.title = 'Tomato Rice Bowl'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_dietary_tags rdt
    WHERE rdt.recipe_id = r.recipe_id AND rdt.dietary_tag_id = d.dietary_tag_id
  );

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, u.measurement_unit_id, 200.000, 1
FROM recipes r
JOIN ingredients i ON i.ingredient_name = 'Rice'
JOIN measurement_units u ON u.unit_symbol = 'g'
WHERE r.title = 'Tomato Rice Bowl'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.recipe_id AND ri.ingredient_id = i.ingredient_id
      AND ri.measurement_unit_id = u.measurement_unit_id AND ri.sort_order = 1
  );

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, u.measurement_unit_id, 2.000, 2
FROM recipes r
JOIN ingredients i ON i.ingredient_name = 'Tomato'
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE r.title = 'Tomato Rice Bowl'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.recipe_id AND ri.ingredient_id = i.ingredient_id
      AND ri.measurement_unit_id = u.measurement_unit_id AND ri.sort_order = 2
  );

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, u.measurement_unit_id, 1.000, 3
FROM recipes r
JOIN ingredients i ON i.ingredient_name = 'Onion'
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE r.title = 'Tomato Rice Bowl'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.recipe_id AND ri.ingredient_id = i.ingredient_id
      AND ri.measurement_unit_id = u.measurement_unit_id AND ri.sort_order = 3
  );

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, u.measurement_unit_id, 2.000, 1
FROM recipes r
JOIN ingredients i ON i.ingredient_name = 'Egg'
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE r.title = 'Egg on Toast'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.recipe_id AND ri.ingredient_id = i.ingredient_id
      AND ri.measurement_unit_id = u.measurement_unit_id AND ri.sort_order = 1
  );

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, u.measurement_unit_id, 100.000, 2
FROM recipes r
JOIN ingredients i ON i.ingredient_name = 'Milk'
JOIN measurement_units u ON u.unit_symbol = 'ml'
WHERE r.title = 'Egg on Toast'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.recipe_id AND ri.ingredient_id = i.ingredient_id
      AND ri.measurement_unit_id = u.measurement_unit_id AND ri.sort_order = 2
  );

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, u.measurement_unit_id, 2.000, 3
FROM recipes r
JOIN ingredients i ON i.ingredient_name = 'Bread'
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE r.title = 'Egg on Toast'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.recipe_id AND ri.ingredient_id = i.ingredient_id
      AND ri.measurement_unit_id = u.measurement_unit_id AND ri.sort_order = 3
  );

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 1, 'Cook the rice according to the package instructions.'
FROM recipes r
WHERE r.title = 'Tomato Rice Bowl'
  AND NOT EXISTS (SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 2, 'Saute onion and tomato, then serve over rice.'
FROM recipes r
WHERE r.title = 'Tomato Rice Bowl'
  AND NOT EXISTS (SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 2);

INSERT INTO saved_recipes (user_id, recipe_id)
SELECT u.user_id, r.recipe_id
FROM users u
JOIN recipes r ON r.title = 'Tomato Rice Bowl'
WHERE u.email = 'student.alice@unimeal.test'
  AND NOT EXISTS (
    SELECT 1 FROM saved_recipes sr WHERE sr.user_id = u.user_id AND sr.recipe_id = r.recipe_id
  );

INSERT INTO recipe_ratings (user_id, recipe_id, rating)
SELECT u.user_id, r.recipe_id, 5
FROM users u
JOIN recipes r ON r.title = 'Tomato Rice Bowl'
WHERE u.email = 'student.alice@unimeal.test'
ON DUPLICATE KEY UPDATE rating = VALUES(rating);

INSERT INTO recipe_comments (recipe_id, user_id, comment_text)
SELECT r.recipe_id, u.user_id, 'Affordable, quick and easy to make after class.'
FROM recipes r
JOIN users u ON u.email = 'student.alice@unimeal.test'
WHERE r.title = 'Tomato Rice Bowl'
  AND NOT EXISTS (
    SELECT 1 FROM recipe_comments rc
    WHERE rc.recipe_id = r.recipe_id AND rc.user_id = u.user_id
      AND rc.comment_text = 'Affordable, quick and easy to make after class.'
  );

INSERT INTO budget_periods (user_id, period_start, period_end, budget_amount)
SELECT u.user_id, '2026-08-10', '2026-08-16', 60.00
FROM users u
WHERE u.email = 'student.alice@unimeal.test'
ON DUPLICATE KEY UPDATE budget_amount = VALUES(budget_amount);

INSERT INTO meal_plans (user_id, week_start_date, plan_name)
SELECT u.user_id, '2026-08-10', 'Week 4 student meal plan'
FROM users u
WHERE u.email = 'student.alice@unimeal.test'
ON DUPLICATE KEY UPDATE plan_name = VALUES(plan_name);

INSERT INTO meal_plan_entries (meal_plan_id, recipe_id, planned_date, meal_type, servings, notes)
SELECT mp.meal_plan_id, r.recipe_id, '2026-08-10', 'dinner', 2, 'Use pantry rice if available.'
FROM meal_plans mp
JOIN users u ON u.user_id = mp.user_id
JOIN recipes r ON r.title = 'Tomato Rice Bowl'
WHERE u.email = 'student.alice@unimeal.test' AND mp.week_start_date = '2026-08-10'
  AND NOT EXISTS (
    SELECT 1 FROM meal_plan_entries mpe
    WHERE mpe.meal_plan_id = mp.meal_plan_id
      AND mpe.planned_date = '2026-08-10' AND mpe.meal_type = 'dinner'
  );

INSERT INTO shopping_lists (user_id, meal_plan_id, list_name, status)
SELECT u.user_id, mp.meal_plan_id, 'Week 4 groceries', 'active'
FROM users u
JOIN meal_plans mp ON mp.user_id = u.user_id AND mp.week_start_date = '2026-08-10'
WHERE u.email = 'student.alice@unimeal.test'
  AND NOT EXISTS (
    SELECT 1 FROM shopping_lists sl
    WHERE sl.user_id = u.user_id AND sl.meal_plan_id = mp.meal_plan_id
      AND sl.list_name = 'Week 4 groceries'
  );

INSERT INTO shopping_list_items (
  shopping_list_id, ingredient_id, measurement_unit_id, item_name, quantity, estimated_unit_cost
)
SELECT sl.shopping_list_id, i.ingredient_id, u.measurement_unit_id, 'Rice', 200.000, 0.01
FROM shopping_lists sl
JOIN ingredients i ON i.ingredient_name = 'Rice'
JOIN measurement_units u ON u.unit_symbol = 'g'
WHERE sl.list_name = 'Week 4 groceries'
  AND NOT EXISTS (
    SELECT 1 FROM shopping_list_items sli
    WHERE sli.shopping_list_id = sl.shopping_list_id AND sli.item_name = 'Rice'
  );

INSERT INTO shopping_list_items (
  shopping_list_id, ingredient_id, measurement_unit_id, item_name, quantity, estimated_unit_cost
)
SELECT sl.shopping_list_id, i.ingredient_id, u.measurement_unit_id, 'Tomato', 2.000, 0.80
FROM shopping_lists sl
JOIN ingredients i ON i.ingredient_name = 'Tomato'
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE sl.list_name = 'Week 4 groceries'
  AND NOT EXISTS (
    SELECT 1 FROM shopping_list_items sli
    WHERE sli.shopping_list_id = sl.shopping_list_id AND sli.item_name = 'Tomato'
  );

INSERT INTO pantry_items (user_id, ingredient_id, measurement_unit_id, quantity, expiry_date)
SELECT u.user_id, i.ingredient_id, mu.measurement_unit_id, 500.000, '2026-09-01'
FROM users u
JOIN ingredients i ON i.ingredient_name = 'Rice'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE u.email = 'student.alice@unimeal.test'
ON DUPLICATE KEY UPDATE quantity = VALUES(quantity), expiry_date = VALUES(expiry_date);

INSERT INTO notifications (user_id, notification_type, title, message, scheduled_for)
SELECT u.user_id, 'meal_reminder', 'Dinner plan reminder',
  'Tomato Rice Bowl is planned for dinner on Monday.', '2026-08-10 17:00:00'
FROM users u
WHERE u.email = 'student.alice@unimeal.test'
  AND NOT EXISTS (
    SELECT 1 FROM notifications n
    WHERE n.user_id = u.user_id AND n.title = 'Dinner plan reminder'
  );

-- ---------------------------------------------------------------------------
-- Current frontend preview data
-- These records provide the current frontend recipe-card preview data. The
-- existing Alice/Ben records above
-- remain as compact validation fixtures used by validation_queries.sql.
-- ---------------------------------------------------------------------------

INSERT INTO cuisines (cuisine_name) VALUES
  ('Japanese'),
  ('Indian'),
  ('Mediterranean'),
  ('Middle Eastern'),
  ('European')
ON DUPLICATE KEY UPDATE cuisine_name = VALUES(cuisine_name);

INSERT INTO dietary_tags (tag_name, description) VALUES
  ('High Protein', 'Higher-protein recipe'),
  ('Budget', 'Low-cost student-friendly recipe')
ON DUPLICATE KEY UPDATE description = VALUES(description);

INSERT INTO users (
  role_id, email, password_hash, display_name, cooking_skill, kitchen_access, favourite_cuisines_note
)
SELECT role_id, 'student.michael@unimeal.test',
  '$2b$12$wGqxGaBOFmgzYVjYHecpQOtTPKV9kjPOKDU27oOyaHC0VHDDlJ1Ou',
  'Michael Student', 'beginner', 'shared', 'Italian, Japanese, Indian'
FROM roles
WHERE role_name = 'student'
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  cooking_skill = VALUES(cooking_skill),
  kitchen_access = VALUES(kitchen_access),
  favourite_cuisines_note = VALUES(favourite_cuisines_note);

DROP TEMPORARY TABLE IF EXISTS frontend_ingredient_seed;
CREATE TEMPORARY TABLE frontend_ingredient_seed (
  ingredient_name VARCHAR(120) NOT NULL PRIMARY KEY,
  category_name VARCHAR(60) NOT NULL,
  unit_symbol VARCHAR(12) NOT NULL,
  estimated_unit_cost DECIMAL(12,4) NOT NULL
);

INSERT INTO frontend_ingredient_seed (ingredient_name, category_name, unit_symbol, estimated_unit_cost) VALUES
  ('Pasta', 'Grains', 'g', 0.0030),
  ('Tomato', 'Produce', 'pc', 0.5000),
  ('Cream', 'Dairy', 'ml', 0.0080),
  ('Chicken', 'Protein', 'g', 0.0080),
  ('Rice', 'Grains', 'g', 0.0020),
  ('Broccoli', 'Produce', 'g', 0.0050),
  ('Chickpeas', 'Protein', 'g', 0.0030),
  ('Coconut Milk', 'Pantry', 'ml', 0.0060),
  ('Wrap', 'Grains', 'pc', 0.4000),
  ('Hummus', 'Pantry', 'g', 0.0100),
  ('Cucumber', 'Produce', 'pc', 0.6000),
  ('Lentils', 'Protein', 'g', 0.0020),
  ('Carrot', 'Produce', 'pc', 0.3000),
  ('Cumin', 'Pantry', 'g', 0.0200),
  ('Mushrooms', 'Produce', 'g', 0.0070),
  ('Bread', 'Grains', 'pc', 0.2500),
  ('Garlic', 'Produce', 'pc', 0.1000);

INSERT INTO ingredients (
  ingredient_category_id, ingredient_name, default_measurement_unit_id, estimated_unit_cost
)
SELECT ic.ingredient_category_id, fis.ingredient_name, mu.measurement_unit_id, fis.estimated_unit_cost
FROM frontend_ingredient_seed fis
JOIN ingredient_categories ic ON ic.category_name = fis.category_name
JOIN measurement_units mu ON mu.unit_symbol = fis.unit_symbol
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id),
  estimated_unit_cost = VALUES(estimated_unit_cost);

DROP TEMPORARY TABLE IF EXISTS frontend_recipe_seed;
CREATE TEMPORARY TABLE frontend_recipe_seed (
  title VARCHAR(160) NOT NULL PRIMARY KEY,
  cuisine_name VARCHAR(60) NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  description TEXT NOT NULL,
  preparation_minutes SMALLINT UNSIGNED NOT NULL,
  cooking_minutes SMALLINT UNSIGNED NOT NULL,
  difficulty ENUM('easy', 'medium', 'hard') NOT NULL,
  estimated_cost DECIMAL(10,2) NOT NULL
);

-- Costs are stored for one student serving so the current card's price has a
-- one-to-one value. Production APIs should still use servings when returning
-- the per-serving value.
INSERT INTO frontend_recipe_seed VALUES
  ('Creamy Tomato Pasta', 'Italian', 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=80', 'A creamy vegetarian pasta for a quick student dinner.', 5, 20, 'easy', 4.80),
  ('Teriyaki Chicken Rice Bowl', 'Japanese', 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=900&q=80', 'A simple chicken rice bowl with broccoli.', 10, 20, 'easy', 5.60),
  ('Chickpea Coconut Curry', 'Indian', 'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=900&q=80', 'A vegan coconut curry for an affordable dinner.', 10, 25, 'easy', 4.20),
  ('Mediterranean Veggie Wrap', 'Mediterranean', 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?auto=format&fit=crop&w=900&q=80', 'A quick vegetarian wrap with hummus and cucumber.', 10, 5, 'easy', 3.90),
  ('Spiced Lentil Soup', 'Middle Eastern', 'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=900&q=80', 'A budget-friendly lentil soup with warming spices.', 10, 35, 'medium', 3.50),
  ('Garlic Mushroom Toast', 'European', 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=900&q=80', 'Crisp toast topped with garlic mushrooms.', 5, 15, 'easy', 3.20);

INSERT INTO recipes (
  author_user_id, cuisine_id, title, image_url, description, preparation_minutes, cooking_minutes,
  servings, difficulty, estimated_cost, status
)
SELECT u.user_id, c.cuisine_id, frs.title, frs.image_url, frs.description,
  frs.preparation_minutes, frs.cooking_minutes, 1, frs.difficulty, frs.estimated_cost, 'published'
FROM frontend_recipe_seed frs
JOIN users u ON u.email = 'contributor.ben@unimeal.test'
JOIN cuisines c ON c.cuisine_name = frs.cuisine_name
LEFT JOIN recipes r ON r.title = frs.title
WHERE r.recipe_id IS NULL;

UPDATE recipes r
JOIN frontend_recipe_seed frs ON frs.title = r.title
JOIN cuisines c ON c.cuisine_name = frs.cuisine_name
SET r.cuisine_id = c.cuisine_id,
    r.image_url = frs.image_url,
    r.description = frs.description,
    r.preparation_minutes = frs.preparation_minutes,
    r.cooking_minutes = frs.cooking_minutes,
    r.servings = 1,
    r.difficulty = frs.difficulty,
    r.estimated_cost = frs.estimated_cost,
    r.status = 'published';

DROP TEMPORARY TABLE IF EXISTS frontend_recipe_tag_seed;
CREATE TEMPORARY TABLE frontend_recipe_tag_seed (
  title VARCHAR(160) NOT NULL,
  tag_name VARCHAR(60) NOT NULL,
  PRIMARY KEY (title, tag_name)
);

INSERT INTO frontend_recipe_tag_seed VALUES
  ('Creamy Tomato Pasta', 'Vegetarian'),
  ('Teriyaki Chicken Rice Bowl', 'High Protein'),
  ('Chickpea Coconut Curry', 'Vegan'),
  ('Chickpea Coconut Curry', 'Gluten-Free'),
  ('Mediterranean Veggie Wrap', 'Vegetarian'),
  ('Spiced Lentil Soup', 'Vegan'),
  ('Spiced Lentil Soup', 'Budget'),
  ('Garlic Mushroom Toast', 'Vegetarian');

INSERT INTO recipe_dietary_tags (recipe_id, dietary_tag_id)
SELECT r.recipe_id, dt.dietary_tag_id
FROM frontend_recipe_tag_seed frts
JOIN recipes r ON r.title = frts.title
JOIN dietary_tags dt ON dt.tag_name = frts.tag_name
ON DUPLICATE KEY UPDATE dietary_tag_id = VALUES(dietary_tag_id);

DROP TEMPORARY TABLE IF EXISTS frontend_recipe_ingredient_seed;
CREATE TEMPORARY TABLE frontend_recipe_ingredient_seed (
  title VARCHAR(160) NOT NULL,
  ingredient_name VARCHAR(120) NOT NULL,
  unit_symbol VARCHAR(12) NOT NULL,
  quantity DECIMAL(10,3) NOT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (title, sort_order)
);

INSERT INTO frontend_recipe_ingredient_seed VALUES
  ('Creamy Tomato Pasta', 'Pasta', 'g', 200.000, 1),
  ('Creamy Tomato Pasta', 'Tomato', 'pc', 4.000, 2),
  ('Creamy Tomato Pasta', 'Cream', 'ml', 100.000, 3),
  ('Teriyaki Chicken Rice Bowl', 'Chicken', 'g', 250.000, 1),
  ('Teriyaki Chicken Rice Bowl', 'Rice', 'g', 300.000, 2),
  ('Teriyaki Chicken Rice Bowl', 'Broccoli', 'g', 150.000, 3),
  ('Chickpea Coconut Curry', 'Chickpeas', 'g', 200.000, 1),
  ('Chickpea Coconut Curry', 'Coconut Milk', 'ml', 300.000, 2),
  ('Chickpea Coconut Curry', 'Rice', 'g', 250.000, 3),
  ('Mediterranean Veggie Wrap', 'Wrap', 'pc', 3.000, 1),
  ('Mediterranean Veggie Wrap', 'Hummus', 'g', 60.000, 2),
  ('Mediterranean Veggie Wrap', 'Cucumber', 'pc', 2.000, 3),
  ('Spiced Lentil Soup', 'Lentils', 'g', 250.000, 1),
  ('Spiced Lentil Soup', 'Carrot', 'pc', 3.000, 2),
  ('Spiced Lentil Soup', 'Cumin', 'g', 5.000, 3),
  ('Garlic Mushroom Toast', 'Mushrooms', 'g', 200.000, 1),
  ('Garlic Mushroom Toast', 'Bread', 'pc', 4.000, 2),
  ('Garlic Mushroom Toast', 'Garlic', 'pc', 3.000, 3);

INSERT INTO recipe_ingredients (
  recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order
)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, fris.quantity, fris.sort_order
FROM frontend_recipe_ingredient_seed fris
JOIN recipes r ON r.title = fris.title
JOIN ingredients i ON i.ingredient_name = fris.ingredient_name
JOIN measurement_units mu ON mu.unit_symbol = fris.unit_symbol
ON DUPLICATE KEY UPDATE
  quantity = VALUES(quantity);

DROP TEMPORARY TABLE IF EXISTS frontend_recipe_step_seed;
CREATE TEMPORARY TABLE frontend_recipe_step_seed (
  title VARCHAR(160) NOT NULL,
  step_number SMALLINT UNSIGNED NOT NULL,
  instruction TEXT NOT NULL,
  PRIMARY KEY (title, step_number)
);

INSERT INTO frontend_recipe_step_seed VALUES
  ('Creamy Tomato Pasta', 1, 'Boil pasta.'),
  ('Creamy Tomato Pasta', 2, 'Make the tomato cream sauce.'),
  ('Creamy Tomato Pasta', 3, 'Combine and serve.'),
  ('Teriyaki Chicken Rice Bowl', 1, 'Cook the rice.'),
  ('Teriyaki Chicken Rice Bowl', 2, 'Pan fry the chicken.'),
  ('Teriyaki Chicken Rice Bowl', 3, 'Assemble the bowl with broccoli.'),
  ('Chickpea Coconut Curry', 1, 'Toast the spices.'),
  ('Chickpea Coconut Curry', 2, 'Simmer chickpeas in coconut milk.'),
  ('Chickpea Coconut Curry', 3, 'Serve with rice.'),
  ('Mediterranean Veggie Wrap', 1, 'Chop the vegetables.'),
  ('Mediterranean Veggie Wrap', 2, 'Fill the wrap with hummus and cucumber.'),
  ('Mediterranean Veggie Wrap', 3, 'Roll and serve.'),
  ('Spiced Lentil Soup', 1, 'Saute the vegetables.'),
  ('Spiced Lentil Soup', 2, 'Simmer the lentils with cumin.'),
  ('Spiced Lentil Soup', 3, 'Blend partly and serve.'),
  ('Garlic Mushroom Toast', 1, 'Toast the bread.'),
  ('Garlic Mushroom Toast', 2, 'Saute mushrooms with garlic.'),
  ('Garlic Mushroom Toast', 3, 'Top the toast and serve.');

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, frss.step_number, frss.instruction
FROM frontend_recipe_step_seed frss
JOIN recipes r ON r.title = frss.title
ON DUPLICATE KEY UPDATE instruction = VALUES(instruction);

INSERT INTO saved_recipes (user_id, recipe_id)
SELECT u.user_id, r.recipe_id
FROM users u
JOIN recipes r ON r.title IN (
  'Creamy Tomato Pasta', 'Teriyaki Chicken Rice Bowl', 'Mediterranean Veggie Wrap'
)
WHERE u.email = 'student.michael@unimeal.test'
ON DUPLICATE KEY UPDATE saved_at = saved_at;

INSERT INTO budget_periods (user_id, period_start, period_end, budget_amount)
SELECT u.user_id, '2026-08-17', '2026-08-23', 45.00
FROM users u
WHERE u.email = 'student.michael@unimeal.test'
ON DUPLICATE KEY UPDATE budget_amount = VALUES(budget_amount);

INSERT INTO meal_plans (user_id, week_start_date, plan_name)
SELECT u.user_id, '2026-08-17', 'Frontend preview meal plan'
FROM users u
WHERE u.email = 'student.michael@unimeal.test'
ON DUPLICATE KEY UPDATE plan_name = VALUES(plan_name);

INSERT INTO meal_plan_entries (meal_plan_id, recipe_id, planned_date, meal_type, servings, notes)
SELECT mp.meal_plan_id, r.recipe_id, '2026-08-23', 'dinner', 1, 'Dashboard tonight preview.'
FROM meal_plans mp
JOIN users u ON u.user_id = mp.user_id
JOIN recipes r ON r.title = 'Chickpea Coconut Curry'
WHERE u.email = 'student.michael@unimeal.test'
  AND mp.week_start_date = '2026-08-17'
ON DUPLICATE KEY UPDATE recipe_id = VALUES(recipe_id), notes = VALUES(notes);

DROP TEMPORARY TABLE IF EXISTS frontend_recipe_step_seed;
DROP TEMPORARY TABLE IF EXISTS frontend_recipe_ingredient_seed;
DROP TEMPORARY TABLE IF EXISTS frontend_recipe_tag_seed;
DROP TEMPORARY TABLE IF EXISTS frontend_recipe_seed;
DROP TEMPORARY TABLE IF EXISTS frontend_ingredient_seed;

COMMIT;
