defmodule TaelBot.Schemas.GuildRole do
  use Ecto.Schema

  @primary_key {:id, :integer, []}

  schema "guilds_roles" do
    field :guild_id, :integer
    field :role_id, :integer
    field :emoji, :string
  end
end
