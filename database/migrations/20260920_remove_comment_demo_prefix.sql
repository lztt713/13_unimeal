-- Remove the display prefix from existing demonstration comments; retain their text.
USE unimeal_planner;
START TRANSACTION;
UPDATE recipe_comments
SET comment_text = SUBSTRING(comment_text, 17)
WHERE LEFT(comment_text, 16) = '[Demo feedback] '
  AND CHAR_LENGTH(TRIM(SUBSTRING(comment_text, 17))) > 0;
COMMIT;
