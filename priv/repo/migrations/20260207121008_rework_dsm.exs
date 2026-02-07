defmodule TaelBot.Repo.Migrations.ReworkDsm do
  use Ecto.Migration

  def up do
    execute("DROP TABLE IF EXISTS discord_streaming_messages")
    execute("""
      CREATE TABLE discord_streaming_messages (
        id INTEGER PRIMARY KEY,
        service TEXT NOT NULL,
        service_id TEXT NOT NULL,
        message_id INTEGER,
        data TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        pending_deletion INT NOT NULL DEFAULT FALSE
      ) STRICT
    """)

    execute("CREATE UNIQUE INDEX idx_discord_streaming_messages_service_service_id ON discord_streaming_messages (service, service_id)");
    execute("CREATE UNIQUE INDEX idx_discord_streaming_messages_message_id ON discord_streaming_messages (message_id)");
  end
end
