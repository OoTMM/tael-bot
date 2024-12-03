-- Truncate this table, it only holds temporary data anyway
TRUNCATE TABLE streams_twitch;

-- Drop useless columns
ALTER TABLE streams_twitch DROP COLUMN user_name, DROP COLUMN title, DROP COLUMN created_at;
