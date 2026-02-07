defmodule TaelBot.Schemas.TwitchStream do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}

  schema "twitch_streams" do
    field :stream_id, :string
    field :user_id, :string
    field :user_name, :string
    field :user_login, :string
    field :title, :string
    field :thumbnail_url, :string
    field :language, :string
    field :viewer_count, :integer
    field :started_at, :utc_datetime
    field :updated_at, :utc_datetime
  end

  def changeset(command, attrs) do
    command
    |> cast(attrs, [
      :id,
      :stream_id,
      :user_id,
      :user_name,
      :user_login,
      :title,
      :thumbnail_url,
      :language,
      :viewer_count,
      :started_at,
      :updated_at,
    ])
  end
end
