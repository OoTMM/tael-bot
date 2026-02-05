defmodule TaelBot.Commands.Helpers do
  @roles %{
    user: 0,
    moderator: 1,
    admin: 2
  }

  def role_from_msg(msg) do
    {:ok, guild} = Nostrum.Cache.GuildCache.get(msg.guild_id)
    role_names = Enum.map(msg.member.roles, fn role_id -> guild.roles[role_id].name end)
    cond do
      "Admin" in role_names -> :admin
      "Moderator" in role_names -> :moderator
      true -> :user
    end
  end

  def require_role!(msg, role) do
    required_level = Map.get(@roles, role, -1)
    user_level = Map.get(@roles, role_from_msg(msg), -1)
    if user_level < required_level, do: throw {:error, :insufficient_permissions}
  end
end
