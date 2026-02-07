defmodule TaelBot.Schemas.DiscordStreamingMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, []}

  schema "discord_streaming_messages" do
    field :service, :string, primary_key: true
    field :service_id, :string, primary_key: true
    field :message_id, :integer
    field :data, :string
    field :updated_at, :utc_datetime_usec
    field :pending_deletion, :boolean, default: false
  end

  def changeset(command, attrs) do
    command
    |> cast(attrs, [
      :service,
      :service_id,
      :message_id,
      :data,
      :updated_at,
      :pending_deletion
    ])
  end
end
