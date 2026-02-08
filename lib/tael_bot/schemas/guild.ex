defmodule TaelBot.Schemas.Guild do
  use Ecto.Schema

  @primary_key {:id, :integer, []}

  schema "guilds" do
    field :role_message_id, :integer
  end
end
