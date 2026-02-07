defmodule TaelBot.Repo.Migrations.AddCommands do
  use Ecto.Migration

  def up do
    execute("""
      CREATE TABLE commands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        value TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    """)

    execute("CREATE UNIQUE INDEX idx_commands_name ON commands (name)");
  end
end
