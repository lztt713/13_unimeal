-- Profile weekly budget and notification deduplication columns.
-- Run once (or safely re-run) on an existing unimeal_planner database.
-- These two columns are the only schema additions needed by the
-- authentication / profile and notification modules.

USE unimeal_planner;

DROP PROCEDURE IF EXISTS apply_profile_and_notifications;

DELIMITER //
CREATE PROCEDURE apply_profile_and_notifications()
BEGIN
  DECLARE weekly_budget_exists INT DEFAULT 0;
  DECLARE dedupe_key_exists INT DEFAULT 0;

  SELECT COUNT(*) INTO weekly_budget_exists
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'users'
    AND column_name = 'weekly_budget';

  IF weekly_budget_exists = 0 THEN
    ALTER TABLE users
      ADD COLUMN weekly_budget DECIMAL(10,2) NOT NULL DEFAULT 0.00
      AFTER favourite_cuisines_note;
  END IF;

  SELECT COUNT(*) INTO dedupe_key_exists
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'notifications'
    AND column_name = 'dedupe_key';

  IF dedupe_key_exists = 0 THEN
    ALTER TABLE notifications
      ADD COLUMN dedupe_key VARCHAR(255) NULL AFTER message;
  END IF;
END //
DELIMITER ;

CALL apply_profile_and_notifications();
DROP PROCEDURE apply_profile_and_notifications;
