defmodule TaelBot.Commands.Handlers.List do
  import TaelBot.Commands.Helpers

  def run(msg, _arg) do
    commands = TaelBot.Commands.list_names()
    |> Enum.map(fn x -> "!" <> x end)
    |> Enum.join(", ")

    reply(msg, "**Available commands:**\n\n" <> commands)
  end
end
