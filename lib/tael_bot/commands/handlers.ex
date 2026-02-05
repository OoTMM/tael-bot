defmodule TaelBot.Commands.Handlers do
  @handlers %{
    "list" => TaelBot.Commands.Handlers.List,
    "cmd" => TaelBot.Commands.Handlers.Cmd,
  }

  def dispatch(msg) do
    "!" <> text = msg.text
    [command_name, command_tail] = case String.split(text, " ", parts: 2) do
      [cmd] -> [cmd, ""]
      parts -> String.trim_leading(parts)
    end

    module = Map.get(@handlers, command_name, TaelBot.Commands.Handlers.Generic)
    try do
      module.run(command_tail, meta)
    catch
      {:error, :insufficient_permissions} ->

    end
  end

  def require_role!(role, min_role) do
    if Map.get(@roles, role, -1) < Map.get(@roles, min_role, -1) do
      throw {:error, :insufficient_permissions}
    end
  end
end
