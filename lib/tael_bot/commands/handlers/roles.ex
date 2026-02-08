defmodule TaelBot.Commands.Handlers.Roles do
  import TaelBot.Commands.Helpers
  alias TaelBot.Schemas.Guild

  @handlers %{
    "msg" => :handle_msg,
  }

  @handlers_msg %{
    "set" => :handle_msg_set,
    "edit" => :handle_msg_edit,
  }

  def run(msg, arg) do
    require_role!(msg, :admin)

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

  def handle_msg(msg, arg) do
    cmd = case String.split(arg, " ", parts: 2) do
      [a, b] -> {:ok, [a, String.trim_leading(b)]}
      [a] -> {:ok, [a, ""]}
      _ -> {:error, :invalid_arguments}
    end

    case cmd do
      {:ok, [subcmd, subargs]} ->
        case Map.get(@handlers_msg, subcmd) do
          nil -> reply(msg, "Unknown subcommand")
          handler -> apply(__MODULE__, handler, [msg, subargs])
        end
      {:error, :invalid_arguments} ->
        reply(msg, "Available subcommands: " <> Enum.join(Map.keys(@handlers_msg), ", "))
    end
  end

  def handle_msg_set(msg, _arg) do
    case Nostrum.Api.Message.create(msg.channel_id, content: "PLACEHOLDER ROLE MESSAGE") do
      {:ok, message} ->
        TaelBot.Repo.insert_all(Guild, [%{id: msg.guild_id, role_channel_id: msg.channel_id, role_message_id: message.id}], on_conflict: {:replace, [:role_channel_id, :role_message_id]}, conflict_target: :id)
      {:error, _} ->
        reply(msg, "Failed to create role message.")
    end
  end

  def handle_msg_edit(msg, arg) do
    guild = TaelBot.Repo.get(Guild, msg.guild_id)
    if guild && guild.role_message_id && guild.role_channel_id do
      case Nostrum.Api.Message.edit(guild.role_channel_id, guild.role_message_id, content: arg) do
        {:ok, _} -> :ok
        {:error, _} -> reply(msg, "Failed to edit role message.")
      end
    else
      reply(msg, "Role message not set. Use `!roles msg set` to create it.")
    end
  end
end
