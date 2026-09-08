-- Fill missing seed recipe details only. Existing lines, servings and prices are preserved.
-- Images are bundled under unimeal_frontend/public/images/recipes.
USE unimeal_planner;
START TRANSACTION;

UPDATE recipes SET image_url = '/images/recipes/tomato-rice-bowl.png' WHERE title = 'Tomato Rice Bowl' AND (image_url IS NULL OR TRIM(image_url) = '');

UPDATE recipes SET image_url = '/images/recipes/egg-on-toast.png' WHERE title = 'Egg on Toast' AND (image_url IS NULL OR TRIM(image_url) = '');

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 200.0, 1
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Pasta'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Creamy Tomato Pasta' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 4.0, 2
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Tomato'
JOIN measurement_units mu ON mu.unit_symbol = 'pc'
WHERE r.title = 'Creamy Tomato Pasta' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 100.0, 3
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Cream'
JOIN measurement_units mu ON mu.unit_symbol = 'ml'
WHERE r.title = 'Creamy Tomato Pasta' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 250.0, 1
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Chicken'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Teriyaki Chicken Rice Bowl' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 300.0, 2
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Rice'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Teriyaki Chicken Rice Bowl' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 150.0, 3
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Broccoli'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Teriyaki Chicken Rice Bowl' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 200.0, 1
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Chickpeas'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Chickpea Coconut Curry' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 300.0, 2
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Coconut Milk'
JOIN measurement_units mu ON mu.unit_symbol = 'ml'
WHERE r.title = 'Chickpea Coconut Curry' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 250.0, 3
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Rice'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Chickpea Coconut Curry' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 3.0, 1
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Wrap'
JOIN measurement_units mu ON mu.unit_symbol = 'pc'
WHERE r.title = 'Mediterranean Veggie Wrap' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 60.0, 2
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Hummus'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Mediterranean Veggie Wrap' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 2.0, 3
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Cucumber'
JOIN measurement_units mu ON mu.unit_symbol = 'pc'
WHERE r.title = 'Mediterranean Veggie Wrap' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 250.0, 1
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Lentils'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Spiced Lentil Soup' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 3.0, 2
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Carrot'
JOIN measurement_units mu ON mu.unit_symbol = 'pc'
WHERE r.title = 'Spiced Lentil Soup' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 5.0, 3
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Cumin'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Spiced Lentil Soup' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 200.0, 1
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Mushrooms'
JOIN measurement_units mu ON mu.unit_symbol = 'g'
WHERE r.title = 'Garlic Mushroom Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 4.0, 2
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Bread'
JOIN measurement_units mu ON mu.unit_symbol = 'pc'
WHERE r.title = 'Garlic Mushroom Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, measurement_unit_id, quantity, sort_order)
SELECT r.recipe_id, i.ingredient_id, mu.measurement_unit_id, 3.0, 3
FROM recipes r JOIN ingredients i ON i.ingredient_name = 'Garlic'
JOIN measurement_units mu ON mu.unit_symbol = 'pc'
WHERE r.title = 'Garlic Mushroom Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.recipe_id
 AND ri.ingredient_id = i.ingredient_id AND ri.measurement_unit_id = mu.measurement_unit_id);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 1, 'Boil pasta.' FROM recipes r
WHERE r.title = 'Creamy Tomato Pasta' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 2, 'Make the tomato cream sauce.' FROM recipes r
WHERE r.title = 'Creamy Tomato Pasta' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 2);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 3, 'Combine and serve.' FROM recipes r
WHERE r.title = 'Creamy Tomato Pasta' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 3);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 1, 'Cook the rice.' FROM recipes r
WHERE r.title = 'Teriyaki Chicken Rice Bowl' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 2, 'Pan fry the chicken.' FROM recipes r
WHERE r.title = 'Teriyaki Chicken Rice Bowl' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 2);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 3, 'Assemble the bowl with broccoli.' FROM recipes r
WHERE r.title = 'Teriyaki Chicken Rice Bowl' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 3);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 1, 'Toast the spices.' FROM recipes r
WHERE r.title = 'Chickpea Coconut Curry' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 2, 'Simmer chickpeas in coconut milk.' FROM recipes r
WHERE r.title = 'Chickpea Coconut Curry' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 2);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 3, 'Serve with rice.' FROM recipes r
WHERE r.title = 'Chickpea Coconut Curry' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 3);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 1, 'Chop the vegetables.' FROM recipes r
WHERE r.title = 'Mediterranean Veggie Wrap' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 2, 'Fill the wrap with hummus and cucumber.' FROM recipes r
WHERE r.title = 'Mediterranean Veggie Wrap' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 2);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 3, 'Roll and serve.' FROM recipes r
WHERE r.title = 'Mediterranean Veggie Wrap' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 3);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 1, 'Saute the vegetables.' FROM recipes r
WHERE r.title = 'Spiced Lentil Soup' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 2, 'Simmer the lentils with cumin.' FROM recipes r
WHERE r.title = 'Spiced Lentil Soup' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 2);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 3, 'Blend partly and serve.' FROM recipes r
WHERE r.title = 'Spiced Lentil Soup' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 3);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 1, 'Toast the bread.' FROM recipes r
WHERE r.title = 'Garlic Mushroom Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 2, 'Saute mushrooms with garlic.' FROM recipes r
WHERE r.title = 'Garlic Mushroom Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 2);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 3, 'Top the toast and serve.' FROM recipes r
WHERE r.title = 'Garlic Mushroom Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 3);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 1, 'Beat the eggs with the milk.' FROM recipes r
WHERE r.title = 'Egg on Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 2, 'Toast the bread. Scramble the egg mixture in a non-stick pan until set.' FROM recipes r
WHERE r.title = 'Egg on Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 2);

INSERT INTO recipe_steps (recipe_id, step_number, instruction)
SELECT r.recipe_id, 3, 'Spoon the scrambled eggs onto the toast and serve.' FROM recipes r
WHERE r.title = 'Egg on Toast' AND NOT EXISTS (
 SELECT 1 FROM recipe_steps rs WHERE rs.recipe_id = r.recipe_id AND rs.step_number = 3);

COMMIT;
