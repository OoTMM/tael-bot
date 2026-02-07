defmodule TaelBot.Repo.Migrations.AddDiscordStreamMessages do
  use Ecto.Migration

  def up do
    execute("""
      CREATE TABLE discord_streaming_messages (
        service TEXT NOT NULL,
        service_id TEXT NOT NULL,
        message_id TEXT,
        data TEXT NOT NULL,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (service, service_id)
      )
    """)

    execute("CREATE UNIQUE INDEX idx_discord_streaming_messages_message_id ON discord_streaming_messages (message_id)");
  end

  def down do
    execute("DROP TABLE IF EXISTS discord_streaming_messages")
  end
end
