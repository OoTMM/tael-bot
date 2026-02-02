defmodule TaelBot.Commands do
  alias TaelBot.Repo
  alias TaelBot.Commands.Command

  @spec get(String.t()) :: Command.t() | nil
  def get(name) do
    Repo.get_by(Command, name: name)
  end


  def create(attrs) do
    %Command{}
    |> Command.changeset(attrs)
    |> Repo.insert()
  end
end
