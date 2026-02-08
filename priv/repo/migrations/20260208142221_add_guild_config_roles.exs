defmodule TaelBot.Repo.Migrations.AddGuildConfigRoles do
  use Ecto.Migration

  def up do
    execute("""
      CREATE TABLE guilds (
        id INTEGER PRIMARY KEY NOT NULL,
        role_message_id INTEGER
      ) STRICT;
    """)

    execute("CREATE INDEX idx_guilds_on_role_message_id ON guilds (role_message_id)")

    execute("""
      CREATE TABLE guilds_roles (
        id INTEGER PRIMARY KEY NOT NULL,
        guild_id INTEGER NOT NULL,
        role_id INTEGER NOT NULL,
        emoji TEXT NOT NULL
      ) STRICT
    """)

    execute("CREATE UNIQUE INDEX idx_guilds_roles_on_guild_id_and_role_id ON guilds_roles (guild_id, role_id)")
    execute("CREATE UNIQUE INDEX idx_guilds_roles_on_guild_id_and_emoji ON guilds_roles (guild_id, emoji)")
  end

  def down do
    execute("DROP TABLE guilds_roles")
    execute("DROP TABLE guilds")
  end
end
