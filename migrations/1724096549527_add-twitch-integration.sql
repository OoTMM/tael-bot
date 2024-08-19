-- Add table
CREATE TABLE streams_twitch (
  id TEXT PRIMARY KEY NOT NULL,
  user_id TEXT NOT NULL,
  discord_message_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add indices
CREATE UNIQUE INDEX ON streams_twitch (discord_message_id);
CREATE INDEX ON streams_twitch (user_id);
CREATE INDEX ON streams_twitch (updated_at);
