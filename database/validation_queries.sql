-- UniMeal Planner database validation checks
-- Prerequisite: run master_schema.sql and sample_data.sql first.
-- Expected result: every row returned by run_validation_tests() has status PASS.

USE unimeal_planner;

DROP PROCEDURE IF EXISTS run_validation_tests;

DELIMITER //
CREATE PROCEDURE run_validation_tests()
BEGIN
  DECLARE duplicate_email_rejected BOOLEAN DEFAULT FALSE;
  DECLARE foreign_key_rejected BOOLEAN DEFAULT FALSE;
  DECLARE invalid_rating_rejected BOOLEAN DEFAULT FALSE;
  DECLARE invalid_quantity_rejected BOOLEAN DEFAULT FALSE;
  DECLARE invalid_ingredient_cost_rejected BOOLEAN DEFAULT FALSE;
  DECLARE invalid_purchase_state_rejected BOOLEAN DEFAULT FALSE;

  DROP TEMPORARY TABLE IF EXISTS validation_results;
  CREATE TEMPORARY TABLE validation_results (
    test_name VARCHAR(100) NOT NULL,
    status ENUM('PASS', 'FAIL') NOT NULL,
    detail VARCHAR(255) NOT NULL
  );

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET duplicate_email_rejected = TRUE;
    INSERT INTO users (role_id, email, password_hash, display_name)
    SELECT role_id, 'student.alice@unimeal.test',
      '$2b$12$wGqxGaBOFmgzYVjYHecpQOtTPKV9kjPOKDU27oOyaHC0VHDDlJ1Ou', 'Duplicate email test'
    FROM roles
    WHERE role_name = 'student';
  END;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET foreign_key_rejected = TRUE;
    INSERT INTO user_dietary_preferences (user_id, dietary_tag_id)
    SELECT 999999999, dietary_tag_id
    FROM dietary_tags
    WHERE tag_name = 'Vegetarian';
  END;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET invalid_rating_rejected = TRUE;
    UPDATE recipe_ratings rr
    JOIN users u ON u.user_id = rr.user_id
    JOIN recipes r ON r.recipe_id = rr.recipe_id
    SET rr.rating = 6
    WHERE u.email = 'student.alice@unimeal.test' AND r.title = 'Tomato Rice Bowl';
  END;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET invalid_quantity_rejected = TRUE;
    UPDATE recipe_ingredients ri
    JOIN recipes r ON r.recipe_id = ri.recipe_id
    JOIN ingredients i ON i.ingredient_id = ri.ingredient_id
    SET ri.quantity = 0
    WHERE r.title = 'Tomato Rice Bowl' AND i.ingredient_name = 'Rice';
  END;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET invalid_ingredient_cost_rejected = TRUE;
    UPDATE ingredients
    SET estimated_unit_cost = -0.0001
    WHERE ingredient_name = 'Rice';
  END;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET invalid_purchase_state_rejected = TRUE;
    UPDATE shopping_list_items sli
    JOIN shopping_lists sl ON sl.shopping_list_id = sli.shopping_list_id
    SET sli.is_purchased = TRUE, sli.purchased_at = NULL
    WHERE sl.list_name = 'Week 4 groceries' AND sli.item_name = 'Rice';
  END;

  INSERT INTO validation_results (test_name, status, detail) VALUES
    ('Unique email', IF(duplicate_email_rejected, 'PASS', 'FAIL'),
      'Duplicate user email must be rejected.'),
    ('Foreign key', IF(foreign_key_rejected, 'PASS', 'FAIL'),
      'Preference cannot reference a missing user.'),
    ('Rating range', IF(invalid_rating_rejected, 'PASS', 'FAIL'),
      'Recipe rating must remain between 1 and 5.'),
    ('Positive ingredient quantity', IF(invalid_quantity_rejected, 'PASS', 'FAIL'),
      'Recipe ingredient quantity must be greater than zero.'),
    ('Non-negative ingredient unit cost', IF(invalid_ingredient_cost_rejected, 'PASS', 'FAIL'),
      'Ingredient reference unit cost cannot be negative.'),
    ('Purchase-state consistency', IF(invalid_purchase_state_rejected, 'PASS', 'FAIL'),
      'A purchased shopping item needs a purchase timestamp.');

  SELECT test_name, status, detail
  FROM validation_results
  ORDER BY test_name;
END //
DELIMITER ;

CALL run_validation_tests();
DROP PROCEDURE run_validation_tests;
