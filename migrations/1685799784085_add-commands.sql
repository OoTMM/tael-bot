-- Create table
CREATE TABLE commands (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  value TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX commands_name_idx ON commands (name, created_at);
CREATE UNIQUE INDEX commands_name_active_idx ON commands (name, active);

-- Create a view for active commands
CREATE VIEW commands_active AS
  SELECT * FROM commands WHERE active = TRUE;
