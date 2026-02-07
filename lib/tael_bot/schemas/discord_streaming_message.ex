defmodule TaelBot.Schemas.DiscordStreamingMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "discord_streaming_messages" do
    field :service, :string, primary_key: true
    field :service_id, :string, primary_key: true
    field :message_id, :string
    field :data, :string
    field :updated_at, :utc_datetime
  end

  def changeset(command, attrs) do
    command
    |> cast(attrs, [
      :service,
      :service_id,
      :message_id,
      :data,
      :updated_at,
    ])
  end
end
