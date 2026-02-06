defmodule TaelBot.Commands do
  alias TaelBot.Repo
  alias TaelBot.Commands.Command

  import Ecto.Query, only: [from: 2]

  @spec get(String.t()) :: Command.t() | nil
  def get(name) do
    Repo.get_by(Command, name: name)
  end

  def create(attrs) do
    %Command{}
    |> Command.changeset(attrs)
    |> Repo.insert()
  end

  def list_names() do
    q = from c in Command, select: c.name, order_by: [asc: c.name]
    Repo.all(q)
  end
end
