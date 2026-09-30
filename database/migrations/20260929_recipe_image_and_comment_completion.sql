-- Give the fifteen new recipes their own images and complete their demonstration feedback.
-- Safe to re-run: image paths are updated and duplicate comments are not inserted.
USE unimeal_planner;
START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS new_recipe_image_seed;
CREATE TEMPORARY TABLE new_recipe_image_seed (
  recipe_title VARCHAR(160) NOT NULL PRIMARY KEY,
  image_url VARCHAR(500) NOT NULL
) ENGINE=Memory;

INSERT INTO new_recipe_image_seed (recipe_title, image_url) VALUES
  ('Garlic Tomato Pasta', '/images/recipes/garlic-tomato-pasta-20260929.png'),
  ('Chickpea Tomato Rice', '/images/recipes/chickpea-tomato-rice-20260929.png'),
  ('Coconut Lentil Soup', '/images/recipes/coconut-lentil-soup-20260929.png'),
  ('Hummus Veggie Rice Bowl', '/images/recipes/hummus-veggie-rice-bowl-20260929.png'),
  ('Garlic Mushroom Rice Skillet', '/images/recipes/garlic-mushroom-rice-skillet-20260929.png'),
  ('Hummus Carrot Crunch Wrap', '/images/recipes/hummus-carrot-crunch-wrap-20260929.png'),
  ('Tomato Cumin Lentils', '/images/recipes/tomato-cumin-lentils-20260929.png'),
  ('Broccoli Chickpea Pasta', '/images/recipes/broccoli-chickpea-pasta-20260929.png'),
  ('Chicken Garlic Rice Bowl', '/images/recipes/chicken-garlic-rice-bowl-20260929.png'),
  ('Chicken Tomato Pasta', '/images/recipes/chicken-tomato-pasta-20260929.png'),
  ('Creamy Chicken Mushroom Pasta', '/images/recipes/creamy-chicken-mushroom-pasta-20260929.png'),
  ('Broccoli Egg Fried Rice', '/images/recipes/broccoli-egg-fried-rice-20260929.png'),
  ('Mushroom Lentil Risotto', '/images/recipes/mushroom-lentil-risotto-20260929.png'),
  ('Tomato Egg Pasta', '/images/recipes/tomato-egg-pasta-20260929.png'),
  ('Cumin Chickpea Rice Skillet', '/images/recipes/cumin-chickpea-rice-skillet-20260929.png');

UPDATE recipes recipe
JOIN new_recipe_image_seed seed ON seed.recipe_title = recipe.title
SET recipe.image_url = seed.image_url;

DROP TEMPORARY TABLE IF EXISTS new_recipe_comment_seed;
CREATE TEMPORARY TABLE new_recipe_comment_seed (
  recipe_title VARCHAR(160) NOT NULL,
  reviewer_email VARCHAR(255) NOT NULL,
  comment_text TEXT NOT NULL,
  PRIMARY KEY (recipe_title, reviewer_email)
) ENGINE=InnoDB;

INSERT INTO new_recipe_comment_seed (recipe_title, reviewer_email, comment_text) VALUES
  ('Garlic Tomato Pasta', 'student.alice@unimeal.test', 'The tomato and garlic sauce is quick to make and works well for a low-cost dinner.'),
  ('Garlic Tomato Pasta', 'student.michael@unimeal.test', 'Saving a little pasta water made it easier to coat the noodles evenly.'),
  ('Chickpea Tomato Rice', 'student.alice@unimeal.test', 'The cumin and coconut milk give the chickpeas a comforting flavour.'),
  ('Chickpea Tomato Rice', 'student.michael@unimeal.test', 'Draining the chickpeas first kept the rice bowl from becoming watery.'),
  ('Coconut Lentil Soup', 'student.alice@unimeal.test', 'This soup is filling and the vegetables make it a good meal-prep option.'),
  ('Coconut Lentil Soup', 'student.michael@unimeal.test', 'Adding the coconut milk at the end kept the soup smooth and creamy.'),
  ('Hummus Veggie Rice Bowl', 'student.alice@unimeal.test', 'The fresh cucumber and tomato give the warm rice bowl a nice contrast.'),
  ('Hummus Veggie Rice Bowl', 'student.michael@unimeal.test', 'I liked using the hummus as a quick protein-rich topping.'),
  ('Garlic Mushroom Rice Skillet', 'student.alice@unimeal.test', 'Cooking the mushrooms until browned gives this simple skillet much more flavour.'),
  ('Garlic Mushroom Rice Skillet', 'student.michael@unimeal.test', 'The steps are easy to follow when the rice is prepared first.'),
  ('Hummus Carrot Crunch Wrap', 'student.alice@unimeal.test', 'A useful no-cook lunch with plenty of crunch from the vegetables.'),
  ('Hummus Carrot Crunch Wrap', 'student.michael@unimeal.test', 'Rolling the wrap tightly helps keep the hummus filling in place.'),
  ('Tomato Cumin Lentils', 'student.alice@unimeal.test', 'The tomato and cumin make the lentils feel hearty without needing many ingredients.'),
  ('Tomato Cumin Lentils', 'student.michael@unimeal.test', 'I found the stock amount gave the lentils a good spoonable texture.'),
  ('Broccoli Chickpea Pasta', 'student.alice@unimeal.test', 'Adding broccoli near the end of the pasta cooking time kept it bright and tender.'),
  ('Broccoli Chickpea Pasta', 'student.michael@unimeal.test', 'The chickpeas make this pasta more filling for a budget meal.'),
  ('Chicken Garlic Rice Bowl', 'student.alice@unimeal.test', 'The chicken and broccoli combination makes this a practical high-protein dinner.'),
  ('Chicken Garlic Rice Bowl', 'student.michael@unimeal.test', 'Preparing the rice first made the final bowl easy to assemble.'),
  ('Chicken Tomato Pasta', 'student.alice@unimeal.test', 'The fresh tomato sauce keeps the chicken pasta lighter than a creamy version.'),
  ('Chicken Tomato Pasta', 'student.michael@unimeal.test', 'Cutting the chicken into small pieces helped everything cook at the same pace.'),
  ('Creamy Chicken Mushroom Pasta', 'student.alice@unimeal.test', 'The mushroom and cream sauce is satisfying and the instructions are clear.'),
  ('Creamy Chicken Mushroom Pasta', 'student.michael@unimeal.test', 'Keeping the heat low after adding cream prevented the sauce from splitting.'),
  ('Broccoli Egg Fried Rice', 'student.alice@unimeal.test', 'The egg and broccoli make this a colourful fried rice with good protein.'),
  ('Broccoli Egg Fried Rice', 'student.michael@unimeal.test', 'Using cooled rice made it easier to stir without the grains sticking together.'),
  ('Mushroom Lentil Risotto', 'student.alice@unimeal.test', 'The gradual stock additions make the longer cooking method easy to understand.'),
  ('Mushroom Lentil Risotto', 'student.michael@unimeal.test', 'The lentils add texture and make the risotto more filling.'),
  ('Tomato Egg Pasta', 'student.alice@unimeal.test', 'The egg adds extra protein while keeping the tomato pasta simple.'),
  ('Tomato Egg Pasta', 'student.michael@unimeal.test', 'Stirring gently after adding the egg gave the sauce a soft texture.'),
  ('Cumin Chickpea Rice Skillet', 'student.alice@unimeal.test', 'The chickpeas and rice make this one-pan dish a practical vegan option.'),
  ('Cumin Chickpea Rice Skillet', 'student.michael@unimeal.test', 'The coconut milk balances the cumin and tomato nicely.' );

INSERT INTO recipe_comments (recipe_id, user_id, comment_text, is_hidden)
SELECT recipe.recipe_id, reviewer.user_id, seed.comment_text, FALSE
FROM new_recipe_comment_seed seed
JOIN recipes recipe ON recipe.title = seed.recipe_title
JOIN users reviewer ON reviewer.email = seed.reviewer_email
WHERE NOT (seed.recipe_title = 'Cumin Chickpea Rice Skillet'
           AND (recipe.description = 'Dry-fried cumin chickpea rice with broccoli and carrot for a colourful vegetable skillet.'
             OR EXISTS (SELECT 1 FROM recipe_ingredients revised_line
                        JOIN ingredients revised_ingredient ON revised_ingredient.ingredient_id = revised_line.ingredient_id
                        WHERE revised_line.recipe_id = recipe.recipe_id AND revised_ingredient.ingredient_name = 'Broccoli')))
  AND NOT EXISTS (
  SELECT 1 FROM recipe_comments existing
  WHERE existing.recipe_id = recipe.recipe_id
    AND existing.user_id = reviewer.user_id
    AND existing.comment_text = seed.comment_text
);

DROP TEMPORARY TABLE IF EXISTS new_recipe_comment_seed;
DROP TEMPORARY TABLE IF EXISTS new_recipe_image_seed;
COMMIT;
