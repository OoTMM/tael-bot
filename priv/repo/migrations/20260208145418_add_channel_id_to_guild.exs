defmodule TaelBot.Repo.Migrations.AddChannelIdToGuild do
  use Ecto.Migration

  def up do
    execute("DROP TABLE IF EXISTS guilds")

    execute("""
      CREATE TABLE guilds (
        id INTEGER PRIMARY KEY NOT NULL,
        role_message_id INTEGER,
        role_channel_id INTEGER
      ) STRICT;
    """)

    execute("CREATE INDEX idx_guilds_on_role_message_id ON guilds (role_message_id)")
  end
end
