CREATE TABLE streams_twitch_blacklist (
  user_id TEXT PRIMARY KEY NOT NULL,
  user_login TEXT NOT NULL,
);

-- Add indices
CREATE INDEX ON streams_twitch_blacklist (user_login);
