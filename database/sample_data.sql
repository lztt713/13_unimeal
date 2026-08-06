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

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id)
SELECT c.ingredient_category_id, 'Rice', u.measurement_unit_id
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'g'
WHERE c.category_name = 'Grains'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id)
SELECT c.ingredient_category_id, 'Tomato', u.measurement_unit_id
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE c.category_name = 'Produce'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id)
SELECT c.ingredient_category_id, 'Onion', u.measurement_unit_id
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE c.category_name = 'Produce'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id)
SELECT c.ingredient_category_id, 'Egg', u.measurement_unit_id
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE c.category_name = 'Protein'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id)
SELECT c.ingredient_category_id, 'Milk', u.measurement_unit_id
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'ml'
WHERE c.category_name = 'Dairy'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id);

INSERT INTO ingredients (ingredient_category_id, ingredient_name, default_measurement_unit_id)
SELECT c.ingredient_category_id, 'Bread', u.measurement_unit_id
FROM ingredient_categories c
JOIN measurement_units u ON u.unit_symbol = 'pc'
WHERE c.category_name = 'Grains'
ON DUPLICATE KEY UPDATE
  ingredient_category_id = VALUES(ingredient_category_id),
  default_measurement_unit_id = VALUES(default_measurement_unit_id);

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

COMMIT;
