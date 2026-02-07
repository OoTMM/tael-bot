defmodule TaelBot.Repo.Migrations.EnforceStrict do
  use Ecto.Migration

  def up do
    execute("DROP TABLE IF EXISTS twitch_streams")
    execute("""
      CREATE TABLE twitch_streams (
        id TEXT PRIMARY KEY NOT NULL,
        stream_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_login TEXT NOT NULL,
        title TEXT NOT NULL,
        thumbnail_url TEXT NOT NULL,
        language TEXT NOT NULL,
        viewer_count INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      ) STRICT
    """)

    execute("CREATE UNIQUE INDEX idx_twitch_streams_stream_id ON twitch_streams (stream_id)");
    execute("CREATE INDEX idx_twitch_streams_user_id ON twitch_streams (user_id)");
    execute("CREATE INDEX idx_twitch_streams_user_login ON twitch_streams (user_login)");
    execute("CREATE INDEX idx_twitch_streams_updated_at ON twitch_streams (updated_at)");
  end
end
