-- +goose Up
CREATE TABLE streams_twitch (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    user_login TEXT NOT NULL,
    user_name TEXT NOT NULL,
    title TEXT NOT NULL,
    language TEXT NOT NULL,
    thumbnail_url TEXT NOT NULL,
    viewer_count INTEGER NOT NULL,
    started_at TEXT NOT NULL,
    synced_at TEXT NOT NULL
) STRICT;

CREATE INDEX idx_streams_twitch_synced_at ON streams_twitch (synced_at);
