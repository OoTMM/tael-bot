-- Enable CITEXT
CREATE EXTENSION IF NOT EXISTS citext;

-- Drop active view
DROP VIEW commands_active;

-- Create table for old commands
CREATE TABLE commands_history (
  id SERIAL PRIMARY KEY,
  name CITEXT NOT NULL,
  value TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Copy old commands to history
INSERT INTO commands_history (name, value, created_at)
SELECT name, value, created_at
FROM commands
WHERE active = FALSE;

-- Drop inactive commands
DELETE FROM commands WHERE active = FALSE;

-- Drop old indices
DROP INDEX commands_name_idx;
DROP INDEX commands_name_active_idx;

-- Update old names to lowercase
UPDATE commands
SET name = LOWER(name);

-- Change name to citext
ALTER TABLE commands ALTER COLUMN name SET DATA TYPE CITEXT;

-- Drop active column
ALTER TABLE commands DROP COLUMN active;

-- Add updated_at on commands
ALTER TABLE commands ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();

-- Set updated_at to created_at
UPDATE commands
SET updated_at = created_at;

-- Force updated_at to be not null
ALTER TABLE commands ALTER COLUMN updated_at SET NOT NULL;

-- Create new index
CREATE UNIQUE INDEX commands_name_idx ON commands (name);
