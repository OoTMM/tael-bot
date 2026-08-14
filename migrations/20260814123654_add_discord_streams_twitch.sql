-- +goose Up
CREATE TABLE discord_streams_twitch (
    id TEXT PRIMARY KEY NOT NULL,
    stream_id TEXT NOT NULL
) STRICT;

CREATE INDEX idx_discord_streams_twitch_stream_id ON discord_streams_twitch (stream_id);
