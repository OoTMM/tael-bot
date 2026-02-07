defmodule TaelBot.Commands do
  alias TaelBot.Repo
  alias TaelBot.Commands.Command

  import Ecto.Query, only: [from: 2]

  @spec get(String.t()) :: Command.t() | nil
  def get(name) do
    Repo.get_by(Command, name: name)
  end

  def create(attrs) do
    try do
      %Command{}
      |> Command.changeset(attrs)
      |> Repo.insert()
    rescue
      e -> {:error, e}
    end
  end

  def update(attrs) do
    case Repo.update_all(from(c in Command, where: c.name == ^attrs.name), set: [value: attrs.value]) do
      {0, _} -> {:error, :not_found}
      _ -> {:ok, nil}
    end
  end

  def rename(old_name, new_name) do
    case Repo.update_all(from(c in Command, where: c.name == ^old_name), set: [name: new_name]) do
      {0, _} -> {:error, :not_found}
      _ -> {:ok, nil}
    end
  end

  def delete(name) do
    case Repo.delete_all(from(c in Command, where: c.name == ^name)) do
      {0, _} -> {:error, :not_found}
      _ -> {:ok, nil}
    end
  end

  def list_names() do
    q = from c in Command, select: c.name, order_by: [asc: c.name]
    Repo.all(q)
  end
end
