-- Database-only cooking skill matching for existing profile and notification pages.
-- Beginner -> Easy; Comfortable -> Easy/Medium; Confident -> all difficulties.
USE unimeal_planner;

CREATE OR REPLACE VIEW vw_user_skill_recipe_matches AS
SELECT u.user_id, u.cooking_skill,
       CASE u.cooking_skill WHEN 'beginner' THEN 'Beginner'
            WHEN 'intermediate' THEN 'Comfortable' WHEN 'advanced' THEN 'Confident' END AS cooking_skill_label,
       c.id AS recipe_id, c.title, c.difficulty, c.estimated_cost_per_serving,
       c.cook_time, c.rating, c.review_count
FROM users u
JOIN vw_recipe_cards c
  ON CASE c.difficulty WHEN 'Easy' THEN 1 WHEN 'Medium' THEN 2 WHEN 'Hard' THEN 3 ELSE 99 END
     <= CASE u.cooking_skill WHEN 'beginner' THEN 1 WHEN 'intermediate' THEN 2 WHEN 'advanced' THEN 3 ELSE 0 END
WHERE u.is_active = TRUE;

DROP TRIGGER IF EXISTS trg_users_cooking_skill_suggestions;
DELIMITER $$
CREATE TRIGGER trg_users_cooking_skill_suggestions
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    DECLARE skill_rank INT DEFAULT 0;
    DECLARE skill_label VARCHAR(30);
    DECLARE difficulty_options VARCHAR(60);
    DECLARE matching_count INT DEFAULT 0;
    DECLARE suggestions TEXT;
    IF NOT (OLD.cooking_skill <=> NEW.cooking_skill) AND NEW.is_active = TRUE THEN
        SET skill_rank = CASE NEW.cooking_skill WHEN 'beginner' THEN 1 WHEN 'intermediate' THEN 2 WHEN 'advanced' THEN 3 ELSE 0 END;
        SET skill_label = CASE NEW.cooking_skill WHEN 'beginner' THEN 'Beginner' WHEN 'intermediate' THEN 'Comfortable' WHEN 'advanced' THEN 'Confident' ELSE 'Unknown' END;
        SET difficulty_options = CASE NEW.cooking_skill WHEN 'beginner' THEN 'Easy' WHEN 'intermediate' THEN 'Easy or Medium' WHEN 'advanced' THEN 'Easy, Medium or Hard' ELSE 'None' END;
        SELECT COUNT(*) INTO matching_count
        FROM recipes r WHERE r.status = 'published'
          AND CASE r.difficulty WHEN 'easy' THEN 1 WHEN 'medium' THEN 2 WHEN 'hard' THEN 3 ELSE 99 END <= skill_rank;
        SELECT GROUP_CONCAT(p.title ORDER BY p.level_rank DESC, p.price, p.title SEPARATOR ', ')
        INTO suggestions
        FROM (
            SELECT r.title,
                   CASE r.difficulty WHEN 'easy' THEN 1 WHEN 'medium' THEN 2 WHEN 'hard' THEN 3 ELSE 99 END AS level_rank,
                   r.estimated_cost / NULLIF(r.servings, 0) AS price
            FROM recipes r WHERE r.status = 'published'
              AND CASE r.difficulty WHEN 'easy' THEN 1 WHEN 'medium' THEN 2 WHEN 'hard' THEN 3 ELSE 99 END <= skill_rank
            ORDER BY level_rank DESC, price, r.title LIMIT 3
        ) p;
        INSERT INTO notifications (user_id, notification_type, title, message)
        VALUES (NEW.user_id, 'recipe_update', CONCAT('Cooking skill: ', skill_label),
          CONCAT('Your cooking skill is now ', skill_label, '. ', matching_count,
                 ' published recipes match this skill level. Suggested difficulty: ', difficulty_options,
                 '. ', IF(matching_count > 0, CONCAT('Try: ', suggestions, '. '), ''),
                 'Use the Difficulty filter in Recipe Library. These suggestions match cooking skill only; check ingredients for your allergies.'));
    END IF;
END$$
DELIMITER ;