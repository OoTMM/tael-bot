defmodule TaelBot.Commands.Handlers.Cmd do
  import TaelBot.Commands.Helpers

  @handlers %{
    "add" => :handle_add,
    "edit" => :handle_edit,
    "rename" => :handle_rename,
    "delete" => :handle_delete,
  }

  defp normalize(str) do
    str
    |> String.trim()
    |> String.downcase()
    |> case do
      "!" <> cmd -> cmd
      cmd -> cmd
    end
  end

  defp command_name(str) do
    cmd = normalize(str)
    if String.match?(cmd, ~r/^[a-zA-Z0-9_-]{1,64}$/) do
      {:ok, cmd}
    else
      {:error, "Invalid command name"}
    end
  end

  def run(msg, arg) do
    require_role!(msg, :moderator)
    case String.split(arg, " ", parts: 2) do
      [subcmd, subargs] ->
        case Map.get(@handlers, subcmd) do
          nil -> reply(msg, "Unknown subcommand")
          handler -> apply(__MODULE__, handler, [msg, subargs])
        end
      _ ->
        reply(msg, "Available subcommands: " <> Enum.join(Map.keys(@handlers), ", "))
    end
  end

  def handle_add(msg, arg) do
    case String.split(arg, " ", parts: 2) do
      [name, value] ->
        case command_name(name) do
          {:ok, name} ->
            case TaelBot.Commands.create(%{name: name, value: value}) do
              {:ok, _cmd} -> reply(msg, "Command added successfully")
              {:error, %{type: :unique}} -> reply(msg, "Error: A command with that name already exists")
              {:error, _} -> reply(msg, "Error: Unknown error")
            end
          {:error, reason} ->
            reply(msg, reason)
        end
      _ ->
        reply(msg, "Usage: !cmd add <name> <value>")
    end
  end

  def handle_edit(msg, arg) do
    with [name, value] <- String.split(arg, " ", parts: 2),
         {:ok, name} <- command_name(name) do
      case TaelBot.Commands.update(%{name: name, value: value}) do
        {:ok, _} -> reply(msg, "Command updated successfully")
        {:error, :not_found} -> reply(msg, "Error: Command not found")
        {:error, _} -> reply(msg, "Error: Unknown error")
      end
    else
      _ -> reply(msg, "Usage: !cmd edit <name> <value>")
    end
  end

  def handle_rename(msg, arg) do
    with [old_name, new_name] <- String.split(arg, " ", parts: 2),
         {:ok, old_name} <- command_name(old_name),
         {:ok, new_name} <- command_name(new_name) do
      case TaelBot.Commands.rename(old_name, new_name) do
        {:ok, _} -> reply(msg, "Command renamed successfully")
        {:error, :not_found} -> reply(msg, "Error: Command not found")
        {:error, _} -> reply(msg, "Error: Unknown error")
      end
    else
      _ -> reply(msg, "Usage: !cmd rename <old_name> <new_name>")
    end
  end

  def handle_delete(msg, arg) do
    with {:ok, name} <- command_name(arg) do
      case TaelBot.Commands.delete(name) do
        {:ok, _} -> reply(msg, "Command deleted successfully")
        {:error, :not_found} -> reply(msg, "Error: Command not found")
        {:error, _} -> reply(msg, "Error: Unknown error")
      end
    else
      _ -> reply(msg, "Usage: !cmd delete <name>")
    end
  end
end
