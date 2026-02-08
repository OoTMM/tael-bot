defmodule TaelBot.Commands.Handlers.Roles do
  import TaelBot.Commands.Helpers
  alias TaelBot.Schemas.Guild
  import Ecto.Query

  @handlers %{
    "msg" => :handle_msg,
    "add" => :handle_add,
    "remove" => :handle_remove,
  }

  @handlers_msg %{
    "create" => :handle_msg_create,
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

  def handle_msg_create(msg, _arg) do
    case Nostrum.Api.Message.create(msg.channel_id, content: "PLACEHOLDER ROLE MESSAGE", allowed_mentions: :none) do
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

  def handle_add(msg, arg) do
    [emoji, role] = String.split(arg, " ", parts: 2) |> Enum.map(&String.trim/1)
    guild_cache = Nostrum.Cache.GuildCache.get!(msg.guild_id)
    roles = guild_cache.roles |> Enum.map(fn {k, v} -> {v.name, k} end) |> Enum.into(%{})
    role_id = Map.get(roles, role)
    if role_id do
      guild = TaelBot.Repo.get(Guild, msg.guild_id)
      if guild && guild.role_message_id && guild.role_channel_id do
        Nostrum.Api.Message.react(guild.role_channel_id, guild.role_message_id, URI.encode(emoji))
      end
      :timer.sleep(1000)
      TaelBot.Repo.insert_all(TaelBot.Schemas.GuildRole, [%{guild_id: msg.guild_id, role_id: role_id, emoji: emoji}])
      reply(msg, "Role added: #{role} with emoji #{emoji}")
    else
      reply(msg, "Role not found: #{role}")
    end
  end

  def handle_remove(msg, arg) do
    guild_cache = Nostrum.Cache.GuildCache.get!(msg.guild_id)
    roles = guild_cache.roles |> Enum.map(fn {k, v} -> {v.name, k} end) |> Enum.into(%{})
    role_id = Map.get(roles, arg)
    if role_id do
      guild_role = TaelBot.Repo.get_by(TaelBot.Schemas.GuildRole, guild_id: msg.guild_id, role_id: role_id)
      TaelBot.Repo.delete_all(from gr in TaelBot.Schemas.GuildRole, where: gr.guild_id == ^msg.guild_id and gr.role_id == ^role_id)
      guild = TaelBot.Repo.get(Guild, msg.guild_id)
      if guild && guild.role_message_id && guild.role_channel_id do
        Nostrum.Api.Message.unreact(guild.role_channel_id, guild.role_message_id, URI.encode(guild_role.emoji))
      end
      reply(msg, "Role removed: #{arg}")
    else
      reply(msg, "Role not found: #{arg}")
    end
  end
end
