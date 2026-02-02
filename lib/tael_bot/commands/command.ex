defmodule TaelBot.Commands.Command do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    value: String.t(),
    created_at: NaiveDateTime.t() | nil
  }

  @primary_key {:id, :integer, []}

  schema "commands" do
    field :name, :string
    field :value, :string
    field :created_at, :utc_datetime
  end

  def changeset(command, attrs) do
    command
    |> cast(attrs, [:id, :name, :value])
    |> validate_required([:name, :value])
  end
end
