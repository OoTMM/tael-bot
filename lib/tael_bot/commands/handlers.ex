defmodule TaelBot.Commands.Handlers do
  import TaelBot.Commands.Helpers
  require Logger

  @handlers %{
    "list" => TaelBot.Commands.Handlers.List,
    "cmd" => TaelBot.Commands.Handlers.Cmd,
    "roles" => TaelBot.Commands.Handlers.Roles,
  }

  @spec dispatch(any()) :: any()
  def dispatch(msg) do
    "!" <> text = msg.content
    [command_name, command_tail] = case String.split(text, " ", parts: 2) do
      [cmd, arg] -> [cmd, String.trim_leading(arg)]
      [cmd] -> [cmd, ""]
    end

    try do
      module = Map.get(@handlers, command_name)
      if module, do: module.run(msg, command_tail), else: custom_command(msg, command_name)
    rescue
      e ->
        Logger.error("Error processing command #{command_name}: #{inspect(e)}")
        reply(msg, "An error occurred while processing your command.")
    catch
      {:error, :insufficient_permissions} ->
        reply(msg, "You don't have permission to use this command.")
    end
  end

  def custom_command(msg, command_name) do
    cmd = TaelBot.Commands.get(command_name)
    value = if cmd, do: cmd.value, else: "Command not found."
    reply(msg, value)
  end
end
